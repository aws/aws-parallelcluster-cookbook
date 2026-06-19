# Requirements Document

## Introduction

The Diagnostics Tool is an on-demand, read-only diagnostics utility shipped inside the AWS ParallelCluster AMI (both official and custom). It runs a context-aware set of checks against a running cluster and produces a structured diagnostic report (JSON plus console output). The tool is invoked through the `pcluster-diag` command, available on PATH on any node type (head, compute, login).

The tool exists to reduce operational load and improve the customer troubleshooting experience by (a) making it easy to determine whether a root cause lies outside ParallelCluster, and (b) speeding up root cause analysis on real issues by collecting relevant information in a single run. The tool is designed to be easy to extend so an on-call engineer can add a new check after an investigation, making the same investigation self-diagnosable next time. The tool is updatable from the cookbook GitHub repository via pip without requiring a ParallelCluster release.

This document defines the requirements for the Diagnostics Tool feature. Diagnostics for build-image, automatic remediation, report anonymization, and automated updates in air-gapped environments are out of scope.

## Glossary

- **Diagnostics_Tool**: The overall on-demand, read-only diagnostics utility shipped in the ParallelCluster AMI and invoked via the `pcluster-diag` command.
- **CLI**: The `pcluster-diag` command-line interface, implemented in Python using the Click framework, exposing the `run` and `show` subcommands.
- **Runner**: The component of the Diagnostics_Tool that discovers registered Checks, determines applicability, executes Checks, and aggregates Results.
- **Context_Builder**: The component that builds the Context object at CLI startup.
- **Context**: An object describing the runtime environment, including node type (head, compute, or login) and the deployed cluster configuration.
- **Check**: A registered unit of diagnostic logic exposing `description()`, `should_run(context)`, and `run(context, kwargs)`, uniquely identified by its class simple name.
- **Check_Identifier**: The simple name of a Check class, used to selectively run or exclude a Check.
- **Result**: The outcome of executing a Check, carrying a status, a message, and optional metadata.
- **Status**: One of the values PASSED, ERROR, FAILURE, or SKIPPED describing the outcome of a Check.
- **Report**: The aggregated output of a Diagnostics_Tool execution, produced as a JSON file and as console output.
- **Report_Directory**: The directory `pcluster-diag-output` created under the current working directory where the JSON Report is written.
- **Installer**: The pip-based mechanism used to install or update the Diagnostics_Tool from the cookbook GitHub repository into the virtual environment the tool is installed in (the `cookbook_virtualenv` by default).
- **Diagnostics_Virtualenv**: The optional, nice-to-have dedicated Python virtual environment `pcluster_diag_virtualenv`, controlled by pcluster, into which the Diagnostics_Tool may be installed instead of the shared `cookbook_virtualenv`.
- **Shared_Source_Path**: The optional, nice-to-have cluster-wide shared location `/opt/parallelcluster/shared/diagnostics` where the Diagnostics_Tool source may also be published for cluster-wide use.
- **Node_Local_Copy**: The per-node copy of the Diagnostics_Tool source baked into the AMI; pip installs the tool from this copy by default.
- **Cost_Incurring_Check**: A Check whose execution causes additional monetary cost (for example a scaling check).
- **Support_Policy**: The set of ParallelCluster versions currently covered under the ParallelCluster support policy.
- **Cookbook_Repository**: The `aws-parallelcluster-cookbook` repository, which holds the Diagnostics_Tool source and all implementation changes for this feature.
- **Pcluster_Virtualenv**: Any Python virtual environment created and controlled by pcluster on a node, provisioned with a defined Python version and package set.
- **Changelog**: The CHANGELOG file in the Cookbook_Repository that records notable changes across releases.

## Requirements

### Requirement 1: Command Availability and Invocation Context

**User Story:** As a support engineer, I want to invoke the diagnostics tool from any cluster node, so that I can collect diagnostics regardless of where I am connected.

#### Acceptance Criteria

1. THE Diagnostics_Tool SHALL expose a command named `pcluster-diag` on the system PATH.
1. THE Diagnostics_Tool SHALL be implemented as a Python project installable with pip (used project.toml) based on Click framework, compatible with python 3.10+
2. THE Diagnostics_Tool SHALL be executable on head nodes, compute nodes, and login nodes.
3. THE Diagnostics_Tool SHALL be available on PATH without requiring activation of the virtualenv it is installed in.
4. THE Diagnostics_Tool SHALL perform only read-only operations against the cluster.
5. WHEN the `pcluster-diag` command is invoked with the `--version` option, THE Diagnostics_Tool SHALL print its installed version and exit without building the Context or executing any Checks.

### Requirement 2: Context Construction

**User Story:** As a support engineer, I want the tool to understand the environment it runs in, so that it executes only the checks relevant to the current node and cluster.

#### Acceptance Criteria

1. WHEN the CLI starts, THE Context_Builder SHALL build a Context describing the current environment.
2. THE Context SHALL identify the node type as one of head, compute, or login.
3. THE Context SHALL include the pcluster version, deployed cluster configuration and dna.json.
4. THE Context SHALL include the version of the running Diagnostics_Tool.
5. IF the Context_Builder cannot determine a required environment attribute, THEN THE CLI SHALL terminate startup and SHALL report which attribute could not be determined.
6. IF the Context_Builder cannot build the Context due to a system error, THEN THE CLI SHALL terminate startup and SHALL report the Context build failure.

### Requirement 3: Context-Aware Check Selection and Execution

**User Story:** As an end user, I want the tool to automatically run the checks that apply to my cluster, so that I get a relevant report without manual selection.

#### Acceptance Criteria

1. THE Runner SHALL discover all registered Checks. 
2. Check must be registered manually by the developer so that the developer is in control of the order of execution.
3. WHEN the `run` subcommand is invoked without Check_Identifier arguments, THE Runner SHALL execute every registered Check whose `should_run(context)` returns true for the current Context.
4. WHEN the `run` subcommand is invoked without Check_Identifier arguments, THE Runner SHALL skip every registered Check whose `should_run(context)` returns false for the current Context.
5. THE Runner SHALL execute Checks in the order in which the Checks are registered.
6. WHEN a Check is skipped because `should_run(context)` returns false, THE Runner SHALL record a Result with Status SKIPPED for that Check.
7. IF recording a SKIPPED Result fails, THEN THE Runner SHALL continue executing the remaining Checks.

### Requirement 4: Selective Check Execution

**User Story:** As an on-call engineer, I want to run or exclude specific checks, so that I can target a particular area during an investigation.

#### Acceptance Criteria

1. WHEN the `run` subcommand is invoked with one or more Check_Identifier arguments, THE Runner SHALL execute only the Checks identified by those Check_Identifier arguments.
2. WHEN the `run` subcommand is invoked with the `--exclude` option listing one or more Check_Identifier arguments, THE Runner SHALL execute the applicable Checks except those identified by the `--exclude` arguments.
3. WHEN a Check_Identifier is provided as an explicit `run` argument, THE Runner SHALL execute that Check even when its `should_run(context)` returns false for the current Context.
4. IF a provided Check_Identifier does not match any registered Check, THEN THE CLI SHALL report the unrecognized Check_Identifier and SHALL exit without executing Checks.

### Requirement 5: Listing Available Checks

**User Story:** As an end user, I want to see which checks will run for my context, so that I understand what the tool will inspect before running it.

#### Acceptance Criteria

1. WHEN the `show` subcommand is invoked, THE CLI SHALL list every Check that will run for the current Context.
2. WHEN the `show` subcommand is invoked, THE CLI SHALL display the Check_Identifier and the `description()` text for each listed Check.
3. THE `show` subcommand SHALL perform no Check execution.
4. THE `show` subcommand SHALL  show for each check whether or not it requires user confirmation to be run (when the check method `approval_required()` returns True)

### Requirement 6: Check Interface and Registration

**User Story:** As a developer, I want a uniform check interface and explicit registration, so that checks are consistent and execution order is controlled.

#### Acceptance Criteria

1. THE Diagnostics_Tool SHALL define a Check interface exposing `description()`, `should_run(context)`, `approval_required(context)` and `run(context)`.
2. `description()` returns a string with the human readbale description of the check.
3. `should_run(context)` returns a boolean. When true the check must be executed, when false it must be skipped.
4. `approval_required(context)` returns a boolean, by default it is False. When True, the tool prompts the user to confirm (yes/no) the execution of the check. If the user says no, the check is considerred skipped with message "Skipped by the user".
5. `run(context)` this is the actual execution of the check which returns an object of type `Result`.
6. THE Diagnostics_Tool SHALL identify each Check uniquely by the Check's class simple name.
7. THE Diagnostics_Tool SHALL execute only Checks that are explicitly registered.
8. WHERE a Check class implementing the Check interface is not explicitly registered, THE Diagnostics_Tool SHALL silently ignore that Check without reporting it.
9. IF two Checks are registered with the same class simple name, THEN THE Diagnostics_Tool SHALL emit a warning identifying the duplicated Check_Identifier, SHALL resolve the duplicated Check_Identifier to the first Check registered under that name, and SHALL continue executing the Checks it can.
10. THE Diagnostics_Tool SHALL list all the checks that are going to be executed that requires a confirmartion from the user to be run. The toll will start the execution of the checks only after the user has provided yes/no to each check requigin confirmation,.

### Requirement 7: Check Result Model

**User Story:** As a support engineer, I want each check to return a structured result, so that I can interpret outcomes and the data behind them.

#### Acceptance Criteria

1. WHEN a Check completes execution, THE Check SHALL return a Result with a Status of PASSED, ERROR, FAILURE, or SKIPPED.
2. WHEN a Check returns a Result with Status FAILURE, THE Check SHALL include a message stating the reason for the failure where such a message can be generated.
3. WHEN a Check cannot generate a failure message, THE Check MAY return a Result with Status FAILURE without a message.
4. WHERE a recovery suggestion is available for a failed Check, THE Check SHALL include the recovery suggestion in the Result message.
5. WHEN a Check returns a Result with Status ERROR, THE Check SHALL include the exception stack trace in the Result message.
6. WHERE a Result references underlying data, THE Check SHALL include that data in the Result metadata dictionary.

### Requirement 8: Check Execution Isolation

**User Story:** As an end user, I want one failing check not to stop the others, so that I always get a complete report.

#### Acceptance Criteria

1. IF a Check raises an unhandled exception during execution, THEN THE Runner SHALL record a Result with Status ERROR for that Check and SHALL continue executing the remaining Checks.
2. WHEN a Check returns a Result with Status FAILURE, THE Runner SHALL continue executing the remaining Checks regardless of the failure type.

### Requirement 9: Explicitly Running a Non-Applicable Check

**User Story:** As an on-call engineer, I want to force-run a check whose preconditions are not met, so that I can confirm exactly which preconditions are missing.

#### Acceptance Criteria

1. WHEN a Check is executed explicitly while its `should_run(context)` returns false for the current Context, THE Check SHALL return a Result with Status FAILURE regardless of whether individual preconditions happen to be met.
2. WHEN a Check returns a Result with Status FAILURE due to unmet preconditions, THE Check SHALL include a message identifying the preconditions that are not met.

### Requirement 10: Report Generation

**User Story:** As a support engineer, I want a structured report and readable console output, so that I can share findings and review them in place.

#### Acceptance Criteria

1. WHEN a `run` execution completes, THE Diagnostics_Tool SHALL write a JSON Report into the Report_Directory under the current working directory.
2. WHEN a `run` execution completes, THE Diagnostics_Tool SHALL emit console output equivalent to the JSON Report.
3. THE Report SHALL include, for each executed Check, the Check_Identifier, the Status, the message, and the metadata.
4. IF the Report_Directory does not exist, THEN THE Diagnostics_Tool SHALL create the Report_Directory before writing the JSON Report.
5. THE Report SHALL be serializable to JSON for writing, and the Diagnostics_Tool SHALL NOT deserialize a Report back from JSON (the tool only creates and writes Reports).
6. IF writing the JSON Report to the Report_Directory fails, THEN THE `run` command SHALL complete the run successfully with console output only, treating the JSON file write as best-effort;
   the underlying file-writing utility SHALL surface (not suppress) write errors to its caller.
7. THE filename of the JSON report SHALL include a human-readable timestamp formatted YYYY-MM-DDThh-mm-ss, generated when the report is written.

### Requirement 11: No Additional Permissions or Cost by Default

**User Story:** As a cluster administrator, I want the default diagnostics run to require no extra IAM permissions and incur no extra cost, so that any operator can run it safely.

#### Acceptance Criteria

1. THE Diagnostics_Tool SHALL execute the default set of Checks using only the IAM permissions already available on the node.
2. THE Diagnostics_Tool SHALL execute the default set of Checks without incurring additional monetary cost.
3. WHEN a Cost_Incurring_Check is selected for execution, THE CLI SHALL prompt the user to confirm execution before running that Check.
4. IF the user declines the confirmation prompt for a Cost_Incurring_Check, THEN THE Runner SHALL record a Result with Status SKIPPED for that Check regardless of any other factors.

### Requirement 12: Installation in a pcluster-Controlled Virtual Environment

**User Story:** As a ParallelCluster maintainer, I want the tool installed in a pcluster-controlled virtual environment, so that it is managed consistently with the node's other Python tooling.

#### Acceptance Criteria

1. THE Diagnostics_Tool SHALL be installed into an existing pcluster-controlled Pcluster_Virtualenv on the node; by default this is the `cookbook_virtualenv`.
2. THE Diagnostics_Tool SHALL be baked into both the official ParallelCluster AMI and custom ParallelCluster AMIs as a per-node Node_Local_Copy that pip installs from.
3. WHEN the Diagnostics_Tool is installed from the Node_Local_Copy, THE Installer SHALL NOT access PyPI or any network package index; the required runtime and build dependencies SHALL already be present in the target Pcluster_Virtualenv.
4. (Nice-to-have) THE Diagnostics_Tool source MAY also reside at the Shared_Source_Path for cluster-wide use.
5. (Nice-to-have) WHERE a dedicated Diagnostics_Virtualenv is provisioned instead of reusing the `cookbook_virtualenv`, THE Installer SHALL create it using the same provisioning method, Python version, and package versions used by other Pcluster_Virtualenv environments on the node.

### Requirement 13: Updating the Tool from GitHub

**User Story:** As an end user, I want to update the tool from the cookbook repository, so that I can receive improvements without waiting for a ParallelCluster release.

#### Acceptance Criteria

1. WHERE a user installs the Diagnostics_Tool using pip pointing to the cookbook repository subfolder, THE Installer SHALL install the specified version into the virtualenv the tool is installed in.
2. IF an update fetch from the cookbook repository fails, THEN THE Installer SHALL always attempt to report the failure even if the reporting mechanism itself may fail, and SHALL leave the previously installed version of the Diagnostics_Tool in place.
3. Add a README to the diagnosis tool with instructions on how to fetch and install the latest updates to the tool form github.

### Requirement 14: Source Availability and Fallback

**User Story:** As a support engineer, I want a local fallback when the shared source is unavailable, so that I can still run diagnostics during an outage.

#### Acceptance Criteria

1. THE Diagnostics_Tool SHALL run from its install in the node-local Pcluster_Virtualenv, independent of any cluster-wide shared source.
2. (Nice-to-have) IF the Shared_Source_Path is provisioned and later unavailable, THEN THE Diagnostics_Tool SHALL remain executable from the Node_Local_Copy baked into the AMI.

### Requirement 15: Backward Compatibility

**User Story:** As a ParallelCluster customer, I want the tool to work across supported versions, so that I can use it regardless of my cluster version.

#### Acceptance Criteria

1. THE Diagnostics_Tool SHALL operate on clusters running any ParallelCluster version covered by the Support_Policy.
2. IF the Diagnostics_Tool encounters a supported version it cannot handle due to a compatibility issue, THEN THE Diagnostics_Tool SHALL fail immediately with a clear error message indicating the specific compatibility issue.

### Requirement 16: Implementation Containment

**User Story:** As a ParallelCluster maintainer, I want all implementation changes confined to the cookbook repository, so that the feature can be delivered and reviewed without coordinating changes across other repositories.

#### Acceptance Criteria

1. THE implementation of the Diagnostics_Tool feature SHALL reside entirely within the Cookbook_Repository.
2. THE Diagnostics_Tool feature SHALL be delivered without changes to any repository other than the Cookbook_Repository.

### Requirement 17: Changelog Entry

**User Story:** As a ParallelCluster maintainer, I want the change captured in the changelog, so that the introduction of the Diagnostics_Tool is recorded for release tracking.

#### Acceptance Criteria

1. THE Cookbook_Repository SHALL include an entry in the Changelog that records the introduction of the Diagnostics_Tool feature.
