# no shebang line here, for sourcing ONLY, works in both bash and zsh
# shebang is not working in sourced files!

vault() {
  : '
    Vault

    ShortDesc: This function encrypts and decrypts files and directories using a password.

    Description:
    This function allows for the encryption and decryption of files and directories.
    It uses a password prompt by default, with an optional password file.
    Additionally, an output file can be specified for the decrypted content.

    Parameters:
    - encrypt: If set, the file or directory will be encrypted.
    - decrypt: If set, the file or directory will be decrypted.
    - file: The path to the file or directory to be encrypted or decrypted.
    - password_file: The path to a file containing the password (optional).
    - output_file: The path to save the output file (optional).

    Returns:
    - 0: Success
    - 1: Failure (if file operations or encryption/decryption fails)

    Example Usage:
    vault -e -f ./file.txt -o ./encrypted_file.enc
    vault -d -f ./encrypted_file.enc -o ./decrypted_file.txt
    vault -e -f ./my_directory -o ./encrypted_directory.enc
    vault -d -f ./encrypted_directory.enc -o ./decrypted_directory
  '

  local action=""
  local file=""
  local password_file=""
  local output_file=""

  # Define usage message
  local usage="Usage: vault {-e|-d} -f <file|directory> [-p <password_file>] [-o <output_file>] [-h]
  -e                : Encrypt the file or directory
  -d                : Decrypt the file or directory
  -f <file|directory>: Specify the file or directory to encrypt/decrypt
  -p <password_file>: Optional file containing the password
  -o <output_file>  : Optional output file for the result
  -h                : Show this help message"

  # Parse command-line options
  while getopts ":edf:p:o:h" opt; do
    case $opt in
      e) action="encrypt" ;;
      d) action="decrypt" ;;
      f) file="$OPTARG" ;;
      p) password_file="$OPTARG" ;;
      o) output_file="$OPTARG" ;;
      h) echo "$usage"; return 0 ;;
      \?) echo "Invalid option: -$OPTARG" >&2; echo "$usage"; return 1 ;;
      :) echo "Option -$OPTARG requires an argument." >&2; echo "$usage"; return 1 ;;
    esac
  done

  # Check if either encrypt or decrypt is specified
  if [[ -z "$action" ]]; then
    echo "You must specify either -e (encrypt) or -d (decrypt)."
    echo "$usage"
    return 1
  fi

  # Check if a file or directory is specified
  if [[ -z "$file" ]]; then
    echo "File or directory is required."
    echo "$usage"
    return 1
  fi

  # Read password from the file if provided, else prompt for password
  local password=""
  if [[ -n "$password_file" ]]; then
    password=$(<"$password_file")
  else
    read -sp "Enter password: " password
    echo
  fi

  # Encrypt function
  encrypt() {
    local output_file_final="${output_file:-${file}.enc}"
    
    if [[ -d "$file" ]]; then
      # Encrypting a directory
      tar -czf "${file}.tar.gz" -C "$(dirname "$file")" "$(basename "$file")"
      openssl enc -aes-256-cbc -salt -pbkdf2 -in "${file}.tar.gz" -out "$output_file_final" -pass pass:"$password"
      rm "${file}.tar.gz"
    else
      # Encrypting a file
      openssl enc -aes-256-cbc -salt -pbkdf2 -in "$file" -out "$output_file_final" -pass pass:"$password"
    fi

    if [[ $? -eq 0 ]]; then
      echo "File/Directory encrypted successfully: $output_file_final"
    else
      echo "Encryption failed!"
    fi
  }

  # Decrypt function
  decrypt() {
    local output_file_final="${output_file:-${file%.enc}}"

    if [[ "$file" == *.enc && -d "$file" ]]; then
      # Decrypting a directory
      openssl enc -d -aes-256-cbc -pbkdf2 -in "$file" -out "${output_file_final}.tar.gz" -pass pass:"$password"
      tar -xzf "${output_file_final}.tar.gz" -C "$(dirname "$output_file_final")"
      rm "${output_file_final}.tar.gz"
    else
      # Decrypting a file
      openssl enc -d -aes-256-cbc -pbkdf2 -in "$file" -out "$output_file_final" -pass pass:"$password"
    fi

    if [[ $? -eq 0 ]]; then
      echo "File/Directory decrypted successfully: $output_file_final"
    else
      echo "Decryption failed!"
    fi
  }

  # Perform the action
  if [[ "$action" == "encrypt" ]]; then
    encrypt
  elif [[ "$action" == "decrypt" ]]; then
    decrypt
  else
    echo "Invalid action. Use '-e' for encrypt or '-d' for decrypt."
    return 1
  fi
}

