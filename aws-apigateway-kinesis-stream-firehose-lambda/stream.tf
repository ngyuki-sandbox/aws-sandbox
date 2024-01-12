
resource "aws_kinesis_stream" "stream" {
  name = var.name

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }
}

moved {
  from = aws_kinesis_stream.main
  to   = aws_kinesis_stream.stream
}
