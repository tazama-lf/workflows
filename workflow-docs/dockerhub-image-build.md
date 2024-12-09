## Workflow Name: Publish Docker Image

Purpose: 

- This workflow automates the process of building, tagging, and pushing Docker images to Docker Hub whenever a new release is published.

#### Trigger Events:

`Release`: The workflow is triggered when a release is published.

#### Jobs:

- push_to_registry:

- Runs on: ubuntu-latest

#### Permissions:

`Packages: write:` Allows pushing packages to the Docker registry.

`Contents: read:` Grants read access to the repository contents.

`Attestations: write:` Allows writing attestations.

`ID-Token: write:` Required for generating artifact attestations.

#### Workflow Steps:

- Check Out the Repo:

- Log in to Docker Hub:

Uses docker/login-action to authenticate with Docker Hub using credentials stored in GitHub Secrets.

- Extract Metadata:

Uses docker/metadata-action to generate Docker image tags and labels.

- Build and Push Docker Image:

Uses docker/build-push-action to build the Docker image and push it to Docker Hub with the generated tags and labels.
Generate Artifact Attestation:
