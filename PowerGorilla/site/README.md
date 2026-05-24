# Phat Gorrilla Site

Static promotional website for Phat Gorrilla.

## Free Hosting

The GitHub Pages workflow in `.github/workflows/pages.yml` publishes this folder after the PR is merged into `main`.

In GitHub, set:

```text
Settings > Pages > Build and deployment > Source > GitHub Actions
```

Then run the `Deploy Phat Gorrilla Site` workflow or push to `main`.

## Local Preview

```powershell
cd .\PowerGorilla\site
python -m http.server 4180 --bind 127.0.0.1
```

Open:

```text
http://127.0.0.1:4180/
```
