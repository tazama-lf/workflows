## Workflow Name: DCO (Developer Certificate of Origin)

#### Purpose: 

- This workflow automatically checks whether each commit in a pull request (PR) has a "Signed-off-by" line, ensuring compliance with the Developer Certificate of Origin (DCO).

- Retrieves commits between the head and base branches.

- Verifies that each commit contains a "Signed-off-by" line.

- Lists any non-compliant commits and fails the job if any are found.

- This workflow enforces DCO compliance, ensuring that all contributions are properly signed off, indicating that the contributor agrees to the terms of the DCO.

#### Trigger Events:

`Pull Request`: The workflow triggers whenever a pull request event occurs (e.g., opened, updated).

#### Workflow Steps:

- Checkout Repository:

- Set Up Environment Variables:

- Check for DCO Sign-off:
