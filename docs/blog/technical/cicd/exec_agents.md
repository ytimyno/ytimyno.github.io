# From open source package to credential exfiltration from your build environment

> The problem statement and state of the art when it comes to the security of build environments is introduced in [CI/CD Execution Agents](https://ytimyno.github.io/blog/execution_agents). This is a practical walkthrough of a scenario using a trusted open source package to have access to the build environment and then exploit it.

Sometimes it is hard to articulate the *why should I care about this*. This is a report on a hypothetical scenario where we have a trojanised open-source tool integrated in our build pipelines, and how that can be leveraged to exfiltrate data/credentials, persistence, lateral movement and Denial-of-Service/Wallet attacks. 

It consists of:

1. Creating a malicious Open Source "extra check" for Checkov 
2. (Assumes the user decides to use that extra check fuctionality as there is a GitHub page that looks good enough)
3. When the clitool is executed with the trojanised payload, it will silently attempt to exploit the host

And the exploit shows this is possible:

- Pulling a 'malicious' packages from the outside
- Dumping environment variables (including the build service account 'temporary' access token)
- Zipping the working directory of the build agent and exfiltrating it (includes logs, built artefacts of every pipeline, from any project, that has being executed)
- Replacing the binary that controls the Azure DevOps build agent service with one that skips the secret redaction for future pipelines executed


## Walkthrough

> **Scenario**: You have a goal. You need to ensure the resources in your development pipelines are being configured according to your policy. You find a GitHub project that does exactly what you need. This project is a fork of the widely used [Checkov](https://github.com/bridgecrewio/checkov) project, which you already use anyway, but adds some useful custom checks.

This is not a new scenario (reused from an earlier article), but it's just as plausible. Alternatively, this could be done by creating any 'useful' CLI tool. I like this scenario because Checkov itself is already trusted and expected to be ran in pipelines, and all we are doing is adding an extension to its out-of-the-box functionality.


### Step #1

When running Checkov checks (custom or not), you are running code, in your environment, with all the permissions the user runinng it has. We will extend the malicious checks in [the pac-on-rails GitHub repository](https://github.com/ytimyno/pac-on-rails/blob/main/checks/malicious) to have an additional a malicious check (COOL_MALI_3) that takes advantage of the access to the underlying build agent.


### Step #2

Assuming the user found this project, read the README, which made it look like any other useful open source CLI tool hosted on GitHub, the user adds a simple switch to the pipeline.
The user runs the pipeline and gets the desired result.

### Step #3

When the pipeline was run, alongside the useful functionality, the trojanised payload also executed and we are to confirm all our objectives were met.

- Pulling 'malicious' packages from the outside
- Dumping environment variables (including the build service account 'temporary' access token)
- Zipping the working directory of the build agent and exfiltrating it (includes logs, built artefacts of every pipeline, from any project, that has being executed)
- Replacing the binary that controls the Azure DevOps build agent service with one that skips the secret redaction for future pipelines executed

> **ℹ️ More details will be added soon.**

## Conclusion

Only do this at home :)


# Other (not so) interesting facts

- Running containarised jobs and tasks in pipelines makes the initialisation of the pipeline workflows take anytime from quick to an annoying amount of time depending on the availability of the images required being already in the build agent.
- The build agent access token is not invalidated after each run. A new one is generated, but the old one stays active (for some time).
- Windows Defender definetely recognised obvious payloads from Metasploit :D