# [pac-on-rails](https://github.com/ytimyno/pac-on-rails)

> The code, tests and research are available in the public repository [pac-on-rails](https://github.com/ytimyno/pac-on-rails), feel free to have a look and tailor to your needs. In here for completeness.

Mini project to automate Policy as Code (PaC) and guardrails to ensure adherence to tagging/labelling policies. Supports Traditional IaC Infrastructure and Container Images.

## Policy Engine 

- The repository holds Checkov custom policies to perform checks against container images' labelling policies. The engine ensures compliance with the specified policy (see customisation section).

- The repository holds Checkov custom policies to perform checks against infrastructure metadata policies (Terraform-defined). The engine ensures compliance with the specified policy (see customisation section).

### Metadata Policy Format (Container Images & Traditional IaC Infrastructure)

The tagging policy is defined using JSON format, allowing for flexible customisation of metadata pairs and their validation rules.

```json
{
    "maintainer": {
        "allowed_values": ".*",
        "version": "1.0",
        "description": "A sample metadata pair - Any value accepted"
    },
    "maintainer_specific": {
        "allowed_values": "^[\w\.-]+@[a-zA-Z0-9-]+\.[a-zA-Z]{2,}$",
        "version": "1.0",
        "description": "A sample metadata pair - Specific regex"
    }
}
```

### Extendable CSP-specific Configuration (Traditional IaC Infrastructure)

Each cloud provider has its own configuration section within the engine. The JSON file lists specific configurations to take, according to the CSP. This is here, not only, but also because CSPs use different terms to refer to the same thing.

This policy is currently applicable to Terraform resources. As you will find out, different providers, and even different resources within the same provider, use different attributes and attribute "paths" to apply metadata at different scopes. 

```json
{
  "azure": {
      "keys": [
          "arm",
          "az",
          "azure",
          "azurerm"
      ],
      "description": "Resources to check for metadata pairs (Azure). To override this, modify this file, leaving it in the working directory checkov runs from.",
      "supported_types": [
          {
              "name": "azurerm_kubernetes_cluster",
              "tag_paths": [
                  {
                      "path": "",
                      "attributes": {
                          "one_of": [],
                          "required": [
                              {
                                  "name": "tags",
                                  "cloud_native": false
                              }
                          ]
                      }
                  },
                  {
                      "path": "default_node_pool",
                      "attributes": {
                          "one_of": [],
                          "required": [
                              {
                                  "name": "tags",
                                  "cloud_native": false
                              }
                          ]
                      }
                  }
              ]
          }
      ]
  }
}
```

- **`csp`**: Configuration related to the CSP resources. Contains details on how to validate tags for that CSP infrastructure.
  - **Example Values**: `azure`, `google`, `aws`

- **`keys`**: List of identifiers used to recognize CSP-related resources. These keywords help in identifying and applying the tagging policy to the correct resource types.
  - **Example Values**: `["arm", "az", "azure", "azurerm"]` or `["gcp", "google", "googlecloud"]`

- **`supported_types`**: List of CSP resource types targeted by the tagging policy. Each type includes specific tag paths and requirements.
  - **Example Values**:
    - **`name`**: The name of the resource type (e.g., `azurerm_kubernetes_cluster`).
    - **`tag_paths`**: List of paths within the resource where tags are validated.
      - **`path`**: Optional sub path eithin the resource configuration, leads to the tags attribute (e.g., `default_node_pool`).
      - **`attributes`**:
        - **`one_of`**: At least one of these must be present (e.g., `tags`).
        - **`required`**: All these attributes must be present (e.g., `tags`).

## Customise
Customise with cloud_specific_configurations.json and policy.json as needed. Else, it will use a pre-def set of values. To customise a file, it needs to be in the dir where checkov runs from (see future work).

## Security Advisory - Before Running
To use extra checks with Checkov CLI tool, we can:

1. Specifying a directory with the extra checks' code, or
2. Specifying a Git repo that contains the extra checks' code.

I'd recommend (1). And if you ask me about number (2), I'd ensure the checks are from a private and/or very well scrutinised git repo. 

Checkov checks are really just running extra code:

- With custom Python checks, it's running custom Python scripts. 
- With custom Python checks from a remote repo, it's running (potentially dangerous) custom Python scripts from a remote repo. 

Sky is the limit here. With or without root privileges, you can leave a mark. My advice is **not to run extra checks unless the code has been reviewed and tested by yourself** (you do have to do the work, the "it's fine, open source means it's safe because everyone can check it" solution has been proven *NOT to work*). This is true with any (especially open source) tool. 

That said, I feel the official Checkov documentation and GitHub pages could be clearer. The only place I could find that lightly touches on this is a small paragraph on best practices in the GitHub page (https://github.com/bridgecrewio/checkov?tab=readme-ov-file#configuration-using-a-config-file).

***Update:*** Reached out to Palo Alto through their [security reports page](https://security.paloaltonetworks.com/report). Checkov documentation has been updated.

### Malicious Check 1 - User + SSH

I done a simple PoC that creates a user, creates a files and runs bash commands. It also installs an openssh server in the machine running Checkov which we can connect to it, using the created user. Installs and user creation requires sudo priviledges, and connections may be harder with FW rules in place, but possibilities are endless, and I have seen loads of scary attacks on workloads. Particularly scary on the integrity side, as we can mess with the filesystem.

    1. Try to SSH (not running, so I have connection refused)
    2. Run malicious check from remote git repo
    3. SSH with the newly created user

### Malicious Check 2 - Infiltrate + Exfiltrate data

Take a step back, what would an attacker want?

- We have (almost arbitrary) command execution 
- I guess we need a way to infiltrate/exfiltrate data!

Queue ***CKV_COOL_MALI_2_CHECK***. This check silently:

1. Clones a remote repository (git clone)
2. Creates a new branch* (git checkout)
3. Creates a file with data about the system in the cloned repo directory (keep it simple for PoC, endless opportunities)
4. Commits file to the .git tree (git add & commit)
5. Pushes to the Git repo (git push)
6. Deletes traces of its activity (shutil.rmtree)

*(because our attacker adheres to best practices and does not push to main ;) )

**I wanted some kind of reverse shell, but was being slowed by some connection refused errors.**

![Who needs a reverse shell anyway...](../../../images/no-revshell-no-problem.jpg)

## Run

### Container Images
checkov -d *containerfile_dir/* --external-checks-dir *checks/metadata/images* --framework dockerfile -c CKV_DOCKER_LABEL_CHECK


### Traditional IaC Infrastructure
checkov -d *terraform_dir/* --external-checks-dir *checks/metadata/infrastructure* -c CKV_TF_METADATA_CHECK 


## Future Work

- Combine Checks: Explore combining Cloud-Native (CN) and traditional IaC checks into a unified metadata validation approach.
- Customize Input Paths: Customize the path to input files (policy.json, cloud_specific_configurations.json) for higher flexibility.

## Feedback & Contact

For questions, feedback, bug reports, please use one of the below:

1. **GitHub Issues:** Report bugs or request features on [GitHub Issues page](https://github.com/ytimyno/pac-on-rails/issues).

2. **Email:** For general feedback, you can email at [ytimyno@gmail.com](mailto:ytimyno@gmail.com).