def app
pipeline {
    parameters {
      booleanParam(defaultValue: true, description: 'Execute pipeline?', name: 'shouldBuild')
    }
    agent none
    stages { 
        stage ('Clone repository') {
            agent any
            steps {
                sh 'rm -rf *'
                script {
                    echo 'Pulling...' + env.BRANCH_NAME
                    checkout scm
                    result = sh (script: "git log -1 | grep '.*\\[ci skip\\].*'", returnStatus: true) 
                    if (result == 0) {
                        echo ("'ci skip' spotted in git commit. Aborting.")
                        env.shouldBuild = "false"
                    }
                }
            }
        } 
        stage('Build and Test app') {
            agent {
                docker { image 'dulcet/ubuntu-docker-node' }
            }
            /* https://stackoverflow.com/questions/42743201/npm-install-fails-in-jenkins-pipeline-in-docker/42957034
            */
            environment {
                HOME = '.'
            }
            when {
                expression {
                    return env.shouldBuild != "false"
                }
            }
            steps {
                sh 'npm install'
                sh 'npm test'
                sh 'echo "Tests passed"'
                sh 'git config --global user.email "brigeshbgp@gmail.com"'
                sh 'git config --global user.name "Jenkins"'
                sh 'git tag -l | xargs git tag -d'
                sh 'git fetch --tags'
                //sh 'npm version major -m "[ci skip] Upgrade to %s"'
                script { 
                    if (env.BRANCH_NAME=="master") {
                        withCredentials([usernamePassword(credentialsId: 'e681cd13-0f88-4a24-8bb5-e42e2245fdc5', passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')]) {
                            sh('git stage package.json')
                            sh('git push https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/singtechs/one2onetool.git HEAD:master')
                        }
                    }
                }
            } 
        }
        stage('Build image') {
            agent any
            when {
                expression {
                    return env.shouldBuild != "false"
                }
            }
            steps {
                script {
                    app = docker.build("singtechs/one2onetool")
                }
            }
        }
        stage('Push image') {
            agent any
            when {
                expression {
                    return env.shouldBuild != "false"
                }
            }
            steps {
                script {
                    docker.withRegistry('https://registry.hub.docker.com', 'docker') {
                        app.push("v_${env.BUILD_NUMBER}")
                        app.push("latest")
                    }
                }
            }
        }
        stage('Deploy image') {
            agent any
            when {
                expression {
                    return env.shouldBuild != "false"
                }
            }
            steps {
                script {
                    sh 'export AWS_DEFAULT_OUTPUT="json"'
                    withCredentials([string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID')]) {
                        sh 'aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID}'
                    }
                    //withCredentials([string(credentialsId: 'AWS_Secret_Access_Key', variable: 'AWS_Secret_Access_Key')]) {
                    //    sh 'aws configure set aws_secret_access_key ${AWS_Secret_Access_Key}'
                    //}
                    sh 'aws configure set default.region ap-southeast-1'
                    if (env.BRANCH_NAME=="staging") {
                        echo 'Staging branch detected, deploying with test data'
                        sh './deploy_ecs.sh -test'
                    } else {
                        sh './deploy_ecs.sh'
                    } 
                }
            }
        } 
        stage('Cleanup image') {
            agent any
            when {
                expression {
                    return env.shouldBuild != "false"
                }
            }
            steps {
                script {
                    sh 'docker rmi -f singtechs/one2onetool:latest'
                    sh 'docker rmi -f registry.hub.docker.com/singtechs/one2onetool:latest'
                    sh 'docker rmi -f registry.hub.docker.com/singtechs/one2onetool:v_$BUILD_NUMBER'
                }
            }
        }
    }
    post {
        failure {
            echo 'Sending Email'
            script {
                def mailRecipients = "brigeshbgp@gmail.com"
                def jobName = currentBuild.fullDisplayName

                emailext body: "FAILED: Job ${env.JOB_NAME} build ${env.BUILD_NUMBER}\n More info at: ${env.BUILD_URL}",
                    to: "${mailRecipients}",
                    recipientProviders: [[$class: 'DevelopersRecipientProvider'], [$class: 'RequesterRecipientProvider']],
                    subject: "Jenkins Build FAILED: Job ${env.JOB_NAME}"
            }
        }
    }
}