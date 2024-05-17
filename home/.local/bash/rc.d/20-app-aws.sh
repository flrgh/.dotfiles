# https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-completion.html#cli-command-completion-linux
if __rc_command_exists aws && __rc_command_exists aws_completer; then
    complete -C "$(command -v aws_completer)" aws
fi
