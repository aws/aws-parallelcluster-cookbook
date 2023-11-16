# Contributing Guidelines

Thank you for your interest in contributing to our project. Whether it's a bug report, new feature, correction, or additional 
documentation, we greatly value feedback and contributions from our community.

Please read through this document before submitting any issues or pull requests to ensure we have all the necessary 
information to effectively respond to your bug report or contribution.


## Reporting Bugs/Feature Requests

We welcome you to use the GitHub issue tracker to report bugs or suggest features.

When filing an issue, please check [existing open](https://github.com/aws/aws-parallelcluster-cookbook/issues), or [recently closed](https://github.com/aws/aws-parallelcluster-cookbook/issues?utf8=%E2%9C%93&q=is%3Aissue%20is%3Aclosed%20), issues to make sure somebody else hasn't already 
reported the issue. Please try to include as much information as you can. Details like these are incredibly useful:

* A reproducible test case or series of steps
* The version of our code being used
* Any modifications you've made relevant to the bug
* Anything unusual about your environment or deployment


## Contributing via Pull Requests
Contributions via pull requests are much appreciated. Before sending us a pull request, please ensure that:

1. You are working against the latest source on the *develop* branch.
2. You check existing open, and recently merged, pull requests to make sure someone else hasn't addressed the problem already.
3. You open an issue to discuss any significant work - we would hate for your time to be wasted.

To send us a pull request, please:

1. Fork the repository.
2. Modify the source; please focus on the specific change you are contributing. If you also reformat all the code, it will be hard for us to focus on your change.
3. Ensure local tests pass.
4. Commit to your fork using clear commit messages.
5. Send us a pull request, answering any default questions in the pull request interface.
6. Pay attention to any automated CI failures reported in the pull request, and stay involved in the conversation.

GitHub provides additional document on [forking a repository](https://help.github.com/articles/fork-a-repo/) and 
[creating a pull request](https://help.github.com/articles/creating-a-pull-request/).


## Finding contributions to work on
Looking at the existing issues is a great way to find something to contribute on. As our projects, by default, use the default GitHub issue labels ((enhancement/bug/duplicate/help wanted/invalid/question/wontfix), looking at any ['help wanted'](https://github.com/aws/aws-parallelcluster-cookbook/labels/help%20wanted) issues is a great place to start. 


## VSCode Developer Environment

We provide a [.devcontainer](../.devcontainer) environment that you can open in VSCode, either automatically via the popup that will
appear in the bottom right, or the command palette for DevContainer -> Reopen in container. The image comes with ruby 2.7 and dependencies installed and then you will shell in as the VSCode user (uid 1000) and can test style, run Python tests:

```bash
cookstyle .
```

or run Python tests (we have version 3.9 in the container)

```bash
tox -e py39-nocov
```

Or go to any of the cookbooks directories and run ChefSpec

```bash
cd cookbooks/aws-parallelcluster-awsbatch
chef exec rspec
cd cookbooks/aws-parallelcluster-computefleet
chef exec rspec
cd cookbooks/aws-parallelcluster-environment
chef exec rspec
cd cookbooks/aws-parallelcluster-platform
chef exec rspec
cd cookbooks/aws-parallelcluster-shared
chef exec rspec
cd cookbooks/aws-parallelcluster-slurm
chef exec rspec
```

Although the uid of 1000 (for the vscode user) likely matches your system user, we recommend that you commit and otherwise interact with git from the outside,
as likely your system credentials are in your actual user home.

## Code of Conduct
This project has adopted the [Amazon Open Source Code of Conduct](https://aws.github.io/code-of-conduct). 
For more information see the [Code of Conduct FAQ](https://aws.github.io/code-of-conduct-faq) or contact 
opensource-codeofconduct@amazon.com with any additional questions or comments.


## Security issue notifications
If you discover a potential security issue in this project we ask that you notify AWS/Amazon Security via our [vulnerability reporting page](http://aws.amazon.com/security/vulnerability-reporting/). Please do **not** create a public github issue.


## Licensing

See the [LICENSE](https://github.com/aws/aws-parallelcluster-cookbook/blob/develop/LICENSE.txt) file for our project's licensing. We will ask you to confirm the licensing of your contribution.

We may ask you to sign a [Contributor License Agreement (CLA)](http://en.wikipedia.org/wiki/Contributor_License_Agreement) for larger changes.
