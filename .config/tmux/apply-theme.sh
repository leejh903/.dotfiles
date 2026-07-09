#!/bin/bash
# Catppuccin 테마를 동적으로 전환하는 스크립트
# dark-notify가 macOS appearance 변경 감지 시 latte.conf/mocha.conf 를 통해 호출됨
#
# catppuccin/tmux 플러그인의 테마 변수들이 `set -ogq` (이미 설정된 경우 덮어쓰지 않음)로
# 초기화되기 때문에, 단순히 source-file을 다시 실행해도 색상이 바뀌지 않음.
# 이를 해결하기 위해 @thm_*, @catppuccin_* 변수를 전부 unset한 뒤 재로드함.

FLAVOR="$1"  # latte 또는 mocha

tmux set -g @catppuccin_flavor "$FLAVOR"

# 기존 테마 변수 전부 초기화 (unset 없이 source하면 이전 flavor 색상이 그대로 남음)
tmux show-options -g | grep -E '^@(thm_|catppuccin_)' | awk '{print $1}' | while IFS= read -r opt; do
    tmux set -ug "$opt" 2>/dev/null || true
done

# flavor를 다시 설정 (위 루프에서 @catppuccin_flavor도 unset됐으므로)
tmux set -g @catppuccin_flavor "$FLAVOR"

tmux source ~/.tmux/plugins/tmux/catppuccin_options_tmux.conf
tmux source ~/.tmux/plugins/tmux/catppuccin_tmux.conf
