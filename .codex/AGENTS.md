# 사용자 전역 작업 지침

## 1Password CLI

- 같은 item에 `password`와 `console password`처럼 label이 겹칠 수 있으므로
  `op item get ... --fields password` 같은 모호한 label 선택을 사용하지 않는다.
- secret field는 JSON에서 정확한 field `id`로 선택한다. 예:
  `op item get <item> --format json | jq -r '.fields[] | select(.id=="password") | .value'`
- secret 값은 출력하지 않는다. 비교가 필요하면 일치 여부와 길이만 확인하고,
  사용한 클립보드와 임시 파일을 즉시 정리한다.
