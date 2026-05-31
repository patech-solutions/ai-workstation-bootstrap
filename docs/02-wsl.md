# WSL2 Ubuntu werklaag

WSL2 is de primaire technische werklaag voor development, scripts en AI tooling.

## Hostname

Binnen WSL gebruiken we de hostnaam uit `BOOTSTRAP_HOSTNAME` (zie `config/bootstrap.env`).

Instellen:

```bash
sudo hostnamectl set-hostname "${BOOTSTRAP_HOSTNAME}-wsl"
```

## Git

Git config wordt automatisch gegenereerd vanuit `config/bootstrap.env` door het bootstrap script. Handmatig:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

## SSH key

```bash
ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)"
```

Public key tonen:

```bash
cat ~/.ssh/id_ed25519.pub
```

Deze key toevoegen aan Gitea.
