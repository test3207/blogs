---
title: '[Devops][Diff coverage check in CI/CD]'
date: 2024-09-07 20:28:21
updated: 2024-09-07 20:28:21
tags:
---

## What's the diff coverage check?

Unlike code coverage checks, which are integrated into most modern CI/CD systems, diff coverage can be a bit more complex. Diff coverage compares the code coverage of the current pull request against the target branch’s coverage, offering a fairer assessment than just looking at overall coverage. Imagine this scenario: your team enforces a rule that blocks PRs from being merged if they reduce overall code coverage below 70%. You’ve worked hard for a week to bring the coverage up to 90% and are ready to take a well-deserved vacation. But when you return two weeks later, coverage has dropped back to 70%! While you were away, your teammates didn’t have to write unit tests, thanks to the buffer your hard work created. Worse yet, those untested changes might even cause issues in production. It’s a frustrating situation!

This is where diff coverage comes in. It ensures that each PR covers its changed lines, at a level you decide is appropriate. Unfortunately, I haven’t seen many CI/CD systems with this feature built-in. Azure DevOps does support it for C# projects, though.

In this post, I’d like to share my approach to implementing this mechanism for a JavaScript project on GitHub. The same ideas can be applied to other programming languages or CI/CD systems as well.

## Build the diff coverage check mechanism

### Demo

Here is the demo repo <https://github.com/test3207/DiffCoverageDemo>

And this is the effect achieved:

[Example fail PR](https://github.com/test3207/DiffCoverageDemo/pull/2)
[Example success PR](https://github.com/test3207/DiffCoverageDemo/pull/3)

In these two PRs, I added a new function, the difference is that I didn't write the unit tests for the first PR, thus it fails to merge.

### The project structure

`.github/workflows`
|-`main.yml`
|-`pull_request.yml`
`.pipelines`
|-`main.yml`
|-`pull_request.yml`
`.gitignore`
`index.js`
`index.test.js`
`jest.config.js`
`package.json`

The whole structure of this repo is quite easy, as this is just a demo, so I basically created this `index.js` file and wrote the sum function only, and added the unit tests in `index.test.js` file.

The `.gitignore`, `jest.config.js`, `package.json` should explain themselves, as I'm using jest for unit test and related coverage check.

You can ignore `.pipelines` folder, as I tried to implement the whole demo on Azure Devops in the first place, yet I found they don't really grant any free pipeline resources easily. So what matters here is the `.github/workflows` folder only.

### The key implementation

As mentioned, the diff coverage compares diff bewteen target branch and current branch, so the first thing we need to know, is the coverage of target branch, which is the "main" branch here in this demo.

So for this `main.yml` workflow:

```yaml=
jobs:
  check-coverage:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install dependencies
        run: npm install
      - name: Run tests
        run: npm run test
      - name: Publish code coverage
        uses: actions/upload-artifact@v4
        with:
          name: coverage
          path: coverage/cobertura-coverage.xml
```

It generates a coverage report every time the main branch changed. It will publish the coverage report to artifact, so we can use it later when we start to compare.

**Tip:** we can either generate the coverage report on main branch, or each time when we create the pull request. It may takes a similar cost when the project is small, but when the project become bigger and bigger, run the unit tests for main branch can cost much more(yep, I mean both money and time).

**Tip:** if you don't really know what some tasks mean here, you can copy the `uses` part and search it. Most of them are github actions in marketplace. They are well documented.

Now for the compare step, let's dive into `pull_request.yml` workflow:

```yaml=
jobs:
  check-diff-coverage:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/setup-node@v4
        with:
          node-version: 20.x
      - uses: actions/checkout@v4
        with:
          path: current
      - name: Install dependencies
        run: npm install
        working-directory: current
      - name: Run tests
        run: npm run test
        working-directory: current

      - uses: actions/checkout@v4
        with:
          ref: main
          path: main
      - name: Get the latest run_id of the main branch's code coverage
        id: get_run_id
        run: |
          run_id=$(curl -s -H "Accept: application/vnd.github.v3+json" -H "Authorization: Bearer ${{ secrets.GITHUB_TOKEN }}" https://api.github.com/repos/$GITHUB_REPOSITORY/actions/runs?branch=main | jq -r '.workflow_runs[0].id')
          echo run_id=$run_id >> $GITHUB_OUTPUT
      - name: Download code coverage report from main branch
        uses: actions/download-artifact@v4
        with:
          name: coverage
          run-id: ${{ steps.get_run_id.outputs.run_id }}
          github-token: ${{ github.token }}
      - name: Put main branch's code coverage report to main folder
        run: mkdir main/coverage && mv cobertura-coverage.xml main/coverage/cobertura-coverage.xml

      - name: Install pycobertura
        run: pip install pycobertura
      - name: Generate diff coverage file
        run: |
          pycobertura diff main/coverage/cobertura-coverage.xml current/coverage/cobertura-coverage.xml --source1 main --source2 current --format json --output diff-coverage.json || echo "exit code $?"
      - name: Publish diff coverage
        uses: actions/upload-artifact@v4
        with:
          name: diff-coverage
          path: diff-coverage.json

      # it looks like
      # {
      #     "files": [
      #         {
      #             "Filename": "index.js",
      #             "Stmts": "+1",
      #             "Miss": "+1",
      #             "Cover": "-33.34%",
      #             "Missing": "6"
      #         }
      #     ],
      #     "total": {
      #         "Filename": "TOTAL",
      #         "Stmts": "+1",
      #         "Miss": "+1",
      #         "Cover": "-33.34%"
      #     }
      # }

      # if stmts is less than or equal to 0, return ok
      # if miss is less than or equal to 0, return ok
      # the diff coverage should be (Stmts - Miss) / Stmts
      - name: Check diff coverage.
        run: |
          cat diff-coverage.json
          Stmt=$(jq -r '.total.Stmts' diff-coverage.json)
          Miss=$(jq -r '.total.Miss' diff-coverage.json)
          Stmt=$(echo $Stmt | sed 's/+//')
          Miss=$(echo $Miss | sed 's/+//')

          if [ "$Stmt" -le 0 ] || [ "$Miss" -le 0 ]; then
            echo "ok"
          else
            DiffCoverage=$(echo "scale=2; ($Stmt - $Miss) / $Stmt" | bc)
            if [ "$(echo "$DiffCoverage < 0.8" | bc)" -eq 1 ]; then
              echo "Diff coverage is less than 80%."
              echo "Current diff coverage is $DiffCoverage."
              exit 1
            else
              echo "Diff coverage is greater than 80%."
            fi
          fi
```

These code blocks are divided into four parts by blank lines.

Part one, we do some initialize work, and checkout to current branch, run the unit test, and generate the coverage report.

Part two, we download coverage report of main branch that we generated in `main.yml`, and checkout the main branch.

Part three, we use this pycobertura tool to generate diff report.

Part four, we check the diff coverage. If it's lower than our limit, we fail it by using exit 1.

**Tip:** Don't really set diff coverage target to 100%.
**Tip:** The key point this workflow can work, is that we generate two cobertura report files, and checkout both main branch and current branch, as we need these things to generate diff check report with pycobertura. This is not the only solution, I believe you can find more solutions for your own projects with different languages and devops platform.

## Improvement

To keep this post still nice and short, I won't add any more content with codes. Just put some improvement ideas here:

### Configure status check in github

The check in the workflow is not enforced. To ensure enforcement, you need to configure "Require status checks to pass" in Rules. You can refer to [github document](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/about-status-checks) to configure.

### Merge main before checking

As you may notice, the result of diff coverage check in this progress can be incorrect if the current branch is not up to date to the main branch. You can either configure ask team to merge remote main once before they create a PR, or merge remote main when comparing in the workflow.

### Skip checking when no js file changes

You can run some git commands to check if js file changes and speed up your pipelines a little.

The end.
