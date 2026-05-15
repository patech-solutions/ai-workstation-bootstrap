# WSL2 Ubuntu werklaag

WSL2 is de primaire technische werklaag voor development, scripts en AI tooling.

## Hostname

Binnen WSL gebruiken we:

```text
patech-wsa-01-wsl
```

Instellen:

```bash
sudo hostnamectl set-hostname patech-wsa-01-wsl
```

## Git

```bash
git config --global user.name "Pascal van de Bor"
git config --global user.email "vandeborp@gmail.com"
```

## SSH key

```bash
ssh-keygen -t ed25519 -C "pascal@patech-wsa-01"
```

Public key tonen:

```bash
cat ~/.ssh/id_ed25519.pub
```

Deze key toevoegen aan Gitea.
