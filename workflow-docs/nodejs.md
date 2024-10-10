## Workflow Name: Node.js CI

#### Purpose:

- This GitHub workflow is designed for Continuous Integration (CI) of a Node.js project. It includes three jobs: building the project, checking the code style, and running tests. Here's a detailed breakdown of the workflow:

#### Environment Variables

`env`:

`GH_TOKEN`: ${{ secrets.GITHUB_TOKEN }}: A secret token used to authenticate with GitHub, stored securely in GitHub secrets.
NPM_SCOPE`: "@frmscoe": The scope for the npm packages, typically used for scoped packages.

``NPM_REGISTRY`: "https://npm.pkg.github.com/": The npm registry URL where the scoped packages are hosted.

`NODE_ENV`: 'test': The environment variable used to specify the environment as 'test'.

`STARTUP_TYPE`: 'nats': A custom environment variable indicating the type of startup, possibly related to the messaging system used in the project.

#### Triggers Events

`push`:

`branches: [ "dev", "main" ]`: The workflow triggers on a push to the dev or main branches.

`pull_request`:

`branches: [ "dev", "main" ]`: The workflow also triggers when a pull request is opened targeting the dev or main branches.
Jobs

- The workflow is divided into three jobs: `build`, `lint`, and `test`.

1. Build Job

#### build:

- runs-on: ubuntu-latest: This job runs on the latest available version of Ubuntu.

- steps:

Checkout the code:

Install dependencies:

run: npm ci: Installs the project dependencies using npm in a clean environment.

Run build:

run: npm run build: Executes the build script to compile the project.

2. Lint Job

#### lint:

- runs-on: ubuntu-latest: The job runs on the latest Ubuntu version.

- steps:

Checkout code:

Install dependencies:

Check linting:

3. Test Job

#### test:

- runs-on: ubuntu-latest: The job runs on Ubuntu.

steps:

Checkout code:

Install dependencies:

Run tests:

#### Summary

- This workflow is a complete CI pipeline for a Node.js project. It tests the code on multiple Node.js versions, checks the code style, and runs the build process. 

- The environment variables and registry settings are configured to work with a specific npm scope hosted on GitHub. The workflow runs on pushes and pull requests to the dev and main branches, ensuring continuous integration of the project code.
