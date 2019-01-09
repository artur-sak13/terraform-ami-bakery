output "encrypted_url" {
  value       = "${data.aws_kms_ciphertext.kms_cipher.ciphertext_blob}"
  description = "the KMS encrypted webhook endpoint"
}
