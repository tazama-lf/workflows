## GitHub Action Workflow Documentation: Release

#### Purpose

- This GitHub Action workflow, named Release Workflow, automates the process of creating a new release based on merged pull requests, generating a changelog, and updating relevant files like CHANGELOG.md and VERSION. 

- The workflow is triggered by a repository_dispatch event, specifically of type release, which can be used to trigger the workflow programmatically.

- This workflow is an automated process that handles the entire release lifecycle, including version bumping, changelog generation, and updating repository files. It's triggered by an external event, making it suitable for use with external tools or scripts that manage release processes. 

- The workflow is robust, ensuring that all necessary release tasks are completed consistently and accurately.

#### Workflow Breakdown

##### Trigger

`on: repository_dispatch`: The workflow is triggered by a repository_dispatch event.

`types: [release`]: The workflow listens for the release event type.

`properties: milestone_number`: The workflow accepts a milestone_number property, which is a string representing the milestone ID associated with the release.

#### Workflow Steps:

- Checkout Repository:

- Get the Latest Tag in the Repository:

- Determine Release Type:

- Bump Version:

- Get Milestone Details:

- Generate Changelog

- Display Changelog:

- Attach Changelog to Release:

- Create Release:

- Update CHANGELOG.md File:

- Update VERSION File:
