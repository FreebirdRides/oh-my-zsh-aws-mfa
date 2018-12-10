mfa_func() {
  AWS_CLI=`which aws`

  if [ $? -ne 0 ]; then
    echo "AWS CLI is not installed; exiting"
    exit 1
  else
    echo "Using AWS CLI found at $AWS_CLI"
  fi

  # 1 or 2 args ok
  if [[ $# -ne 1 && $# -ne 2 ]]; then
    echo "Usage: $0 <MFA_TOKEN_CODE> <AWS_CLI_PROFILE>"
    echo "Where:"
    echo "   <MFA_TOKEN_CODE> = Code from virtual MFA device"
    echo "   <AWS_CLI_PROFILE> = aws-cli profile usually in $HOME/.aws/config"
    exit 2
  fi

  echo "Reading config..."
  if [ -r ~/mfa.cfg ]; then
    . ~/mfa.cfg
  else
    echo "No config found.  Please create your mfa.cfg.  See README.txt for more info."
    exit 2
  fi

  AWS_CLI_PROFILE=${2:-default}
  MFA_TOKEN_CODE=$1
  echo $AWS_CLI_PROFILE
  ARN_OF_MFA=${(P)AWS_CLI_PROFILE}

  echo "AWS-CLI Profile: $AWS_CLI_PROFILE"
  echo "MFA ARN: $ARN_OF_MFA"
  echo "MFA Token Code: $MFA_TOKEN_CODE"

  echo "Your Temporary Creds:"
  aws --profile $AWS_CLI_PROFILE sts get-session-token --duration 129600 \
    --serial-number $ARN_OF_MFA --token-code $MFA_TOKEN_CODE --output text \
    | awk '{printf("export AWS_ACCESS_KEY_ID=\"%s\"\nexport AWS_SECRET_ACCESS_KEY=\"%s\"\nexport AWS_SESSION_TOKEN=\"%s\"\nexport AWS_SECURITY_TOKEN=\"%s\"\n",$2,$4,$5,$5)}' | tee ~/.token_file
}

setToken() {
    #do things with parameters like $1 such as
    mfa_func $1 $2
    source ~/.token_file
    echo "Your creds have been set in your env."
}

alias mfa=setToken