# GPG Keys with Agenix Secrets Setup Guide

This guide explains how to set up GPG keys for Git commit signing using agenix secrets in your NixOS configuration.

## Overview

The configuration now supports storing GPG keys as encrypted secrets using agenix, which provides secure key management and automatic import during system activation.

## Prerequisites

- A GPG key pair (public and private keys)
- Access to the agenix secrets directory
- SSH key configured for agenix decryption

## Step 1: Generate GPG Keys (if needed)

```bash
# Generate a new GPG key
gpg --full-generate-key

# Follow the prompts:
# - Choose RSA and RSA (default)
# - Key size: 4096 bits
# - Key validity: 0 (doesn't expire) or set an expiration date
# - Enter your name: Nick Hartjes
# - Enter email: nick@hartj.es
```

## Step 2: Export Your GPG Keys

```bash
# List your keys to find the key ID
gpg --list-secret-keys --keyid-format=long

# Export private key (replace KEY_ID with your actual key ID)
gpg --armor --export-secret-keys KEY_ID > gpg-private-key.asc

# Export public key
gpg --armor --export KEY_ID > gpg-public-key.asc
```

## Step 3: Encrypt Keys with Agenix

```bash
# Navigate to your secrets directory
cd secrets/nh/

# Encrypt the private key
agenix -e gpg-private-key.age

# Paste the contents of gpg-private-key.asc, save and exit

# Encrypt the public key
agenix -e gpg-public-key.age

# Paste the contents of gpg-public-key.asc, save and exit
```

## Step 4: Configure Secrets in NixOS

The secrets are already configured in [`users/nh/secrets.nix`](../../users/nh/secrets.nix):

```nix
gpg-private-key = {
  file = ../../secrets/nh/gpg-private-key.age;
  path = "/home/nh/.gnupg/private-key.asc";
  mode = "400";
  owner = "nh";
  group = "users";
};
gpg-public-key = {
  file = ../../secrets/nh/gpg-public-key.age;
  path = "/home/nh/.gnupg/public-key.asc";
  mode = "444";
  owner = "nh";
  group = "users";
};
```

## Step 5: Enable GPG Signing

The git configuration in [`users/nh.nix`](../../users/nh.nix) is set to:

```nix
components.development.git = {
  enable = true;
  gpgSigning = {
    enable = true;
    importFromSecrets = true; # This is the default
  };
};
```

## Step 6: Rebuild Your System

```bash
sudo nixos-rebuild switch --flake .
```

## What Happens During Activation

When you rebuild your system, the home-manager activation script will:

1. **Decrypt secrets**: Agenix automatically decrypts your GPG keys to the specified paths
2. **Import keys**: The activation script imports both private and public keys into your GPG keyring
3. **Set trust**: Automatically sets ultimate trust for your own keys
4. **Configure Git**: Git is configured to use GPG signing by default

## Verification

After rebuilding, verify the setup:

```bash
# Check if keys are imported
gpg --list-secret-keys
gpg --list-public-keys

# Test GPG signing
echo "test" | gpg --clearsign

# Make a test commit
git commit --allow-empty -m "Test GPG signing"

# Verify the commit is signed
git log --show-signature -1
```

## Configuration Options

### Custom Key ID

If you want to specify a particular key for signing:

```nix
components.development.git = {
  enable = true;
  gpgSigning = {
    enable = true;
    key = "YOUR_KEY_ID_HERE";
    importFromSecrets = true;
  };
};
```

### Disable Automatic Import

If you prefer to manage GPG keys manually:

```nix
components.development.git = {
  enable = true;
  gpgSigning = {
    enable = true;
    importFromSecrets = false;
  };
};
```

## Security Benefits

1. **Encrypted Storage**: GPG keys are stored encrypted using agenix
2. **Automatic Management**: Keys are imported and configured automatically
3. **Proper Permissions**: Files have correct ownership and permissions
4. **Trust Configuration**: Ultimate trust is automatically set for your keys
5. **Commit Verification**: All commits are signed for authenticity

## Troubleshooting

### Keys Not Imported

Check if the secret files exist:
```bash
ls -la ~/.gnupg/private-key.asc ~/.gnupg/public-key.asc
```

### GPG Agent Issues

Restart the GPG agent:
```bash
gpgconf --kill gpg-agent
gpgconf --launch gpg-agent
```

### Commit Signing Fails

Check GPG configuration:
```bash
git config --global --list | grep gpg
gpg --list-secret-keys
```

### Permission Issues

The activation script sets proper permissions, but if needed:
```bash
chmod 700 ~/.gnupg
chmod 400 ~/.gnupg/private-key.asc
chmod 444 ~/.gnupg/public-key.asc
```

## Adding Keys to Git Platforms

Export your public key and add it to GitHub/GitLab:

```bash
# Export public key for GitHub/GitLab
gpg --armor --export YOUR_KEY_ID

# Copy the output and add it to your account settings
```

This setup provides secure, automated GPG key management with commit signing for your NixOS configuration.