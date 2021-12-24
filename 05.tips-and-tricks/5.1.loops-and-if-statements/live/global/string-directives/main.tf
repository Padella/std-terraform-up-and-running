variable "name" {
  description = "A name to render"
  type        = string
  default     = "Neo"
}

output "if_else_directive" {
  value = "Hello, %{ if var.name != "" }${var.name}%{ else }(unnamed)%{ endif }"
}

variable "names" {
  description = "Names to render"
  type        = list(string)
  default     = ["neo", "trinity", "morpheus"]
}

output "for_directive" {
  value = <<EOF
%{ for name in var.names }
  ${name}
%{ endfor }
EOF
}

output "for_directive_strip_marker" {
  # 스페이스나 줄 바꿈 같은 공백 제거를 위해 문자열 지시자의 앞에 ~ 를 사용
  value = <<EOF
%{~ for name in var.names }
  ${name}
%{~ endfor }
EOF
}