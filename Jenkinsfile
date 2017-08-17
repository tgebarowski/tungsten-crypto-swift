iosNode = 'jenkins-slave-mac'

if ("${env.BRANCH_NAME}" ==~ /PR-\d*/) {
  echo "Performing stages for pull request branch ${env.BRANCH_NAME}"
  runOnNode {
    fullCleanAndSetup()
    unitTest()
    stage('Lint pod') {
      cmd_bundle_exec "fastlane lint"
    }
  }
} else if ("${env.BRANCH_NAME}" ==~ /master/) {
  echo "Performing stages after merge to branch ${env.BRANCH_NAME}"
  
  def provided_token = confirmPublishWithTrunkToken("Cocoapods Trunk Token to publish new version.")

  runOnNode {
    withEnv(["COCOAPODS_TRUNK_TOKEN=${provided_token}"]) {
      wrap([$class: 'MaskPasswordsBuildWrapper', varPasswordPairs: [[password: "${provided_token}", var: 'OBFUSCATE_TOKEN']]]) {
        // Escape any username/password occurance from logs.
        
        fullCleanAndSetup()
        unitTest()
        publishPod()
      }
    }
  }
}

def fullCleanAndSetup() {
  stage('Checkout & Setup') {
    deleteDir()
    checkout scm
    cmd 'git submodule update --init'
    echo "My branch is: ${env.BRANCH_NAME}"
    echo "Install dependences"
    cmd 'export'
    cmd '/usr/local/bin/bundle install --path vendor/bundle'
  }
}

def unitTest() {
  try {
    stage('Test') {
      cmd_bundle_exec "fastlane unit_test"
    }
  } finally {
    collectReports()
  }
}

def publishPod() {
  stage('Publish pod') {
    cmd_bundle_exec "fastlane publish"
  }
}

def collectReports() {
  stage('Archive Reports') {
    step(
      [
        $class: 'XUnitBuilder',
        thresholds: [[$class: 'FailedThreshold', unstableThreshold: '1']],
        tools: [[$class: 'JUnitType', pattern: 'build/reports_output/**/*.junit']]
      ]
    )
    archiveArtifacts artifacts: 'build/reports_output/**/*', fingerprint: true
  }
}

// Helpers

def runOnNode(Closure c) {
  try {
    node(iosNode) {
      c()
    }
  } catch (InterruptedException x) {
    currentBuild.result = 'ABORTED'
  } catch (e) {
    currentBuild.result = 'FAILURE'
    throw e
  }
}

String confirmPublishWithTrunkToken(String message) {
  stage('Get Credentials') {
    timeout(time: 1, unit: 'DAYS') {
        return input(
          message: message, 
          parameters: [
            password(defaultValue: '', description: '', name: 'Token')
          ]
        )
    }
  }
}

// Shell

def cmd(String shellCommand) {
    wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'XTerm']) {
        sh shellCommand
    }
}

def cmd_bundle_exec(String bundlerCommand) {
  cmd "/usr/local/bin/bundle exec ${bundlerCommand}"
}