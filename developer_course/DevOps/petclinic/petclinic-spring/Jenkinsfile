/* Norma Ochoa */
def mvnHome
def pom

def this_group
def this_artifact
def this_artifact_full_name
def this_version
def fileproperties = 'file.properties'
def filePropertiesPathAndName = "${JENKINS_HOME}/workspace/${env.JOB_NAME}/${fileproperties}"

pipeline {
   agent any

   stages {
      stage('Get Build Files') {
         steps {
            echo 'Getting Private Repo'
            git(
               url: 'git@github.com:ochoadevops/jenkins-essential-app-form-class.git',
               credentialsId: 'jenkins-id',
               branch: 'main'
            )

            script {
               mvnHome = tool 'M3'
            }
         }
      }

      stage('Build') {
         steps {
            script {
               // Run the maven build
               withEnv(["MVN_HOME=$mvnHome"])
               {
                  if (isUnix()) {
                     sh '"$MVN_HOME/bin/mvn" package'
                  }
                  /* groovylint-disable-next-line NestedBlockDepth */
                  else {
                     bat(/"%MVN_HOME%\bin\mvn" spring-javaformat:apply  -Dmaven.test.failure.ignore clean package/)
                  }
               }
            }
         }
      }

      stage('Test Results') {
         steps {
            junit '**/target/surefire-reports/TEST-*.xml'
            archiveArtifacts 'target/*.*'
         }
      }



      stage('Setup File Properties') {
         steps {
         // This stage will create a file to include properties for this job
         // so that other jobs can use them. For example, the last build ID,
         // the last Job ID, the Artifact ID, Build Number, etc.

         // Read POM xml file using 'readMavenPom' step ,
         // this step 'readMavenPom' is included in: https://plugins.jenkins.io/pipeline-utility-steps

            script {
               pom = readMavenPom file: './pom.xml'

               // Find built artifact under target folder
               filesByGlob = findFiles(glob: "target/*.${pom.packaging}")

               // Print info from the artifact found. This is good for debuging purposes
               echo '*** Print information found'
               echo "${filesByGlob[0].name} ${filesByGlob[0].path} ${filesByGlob[0].directory} ${filesByGlob[0].length} ${filesByGlob[0].lastModified}"

               // Extract the path from the File found. Good for debuging purposes.
               artifactPath = filesByGlob[0].path
               artifactName = filesByGlob[0].name
               echo "*** this artifactName is: ${artifactName}"
               echo "*** this artifactPath is: ${artifactPath}"

               // Get the values for the file.properties
               this_group = pom.groupId
               this_artifact = pom.artifactId
               this_version = pom.version
               this_artifact_full_name = filesByGlob[0].name

               echo "*** Artifact Info: ${pom.artifactId}, group: ${pom.groupId}, version ${pom.version}"

               // Build the key pair for file.properties
               def outputGroupId = 'Group=' + "$this_group"
               def outputVersion = 'Version=' + "$this_version"
               def outputArtifact = 'ArtifactId=' + "$this_artifact"
               def outputFullBuildId = 'FullBuildId=' + "$this_artifact_full_name"
               def outputJenkinsBuildId = "JenkinsBuildId=${env.BUILD_ID}"
               def outputBuildNumber = "BuildNumber=${env.BUILD_NUMBER}"

               // Build the string that will be added to the file properties
               def allParams = "$outputGroupId" + '\n' + "$outputVersion" + '\n' + "$outputArtifact" + '\n' + "$outputFullBuildId" + '\n' + "$outputJenkinsBuildId" + '\n' + "$outputBuildNumber"

               echo "this is allParams: $allParams"
               echo "File Properties designated location:  $filePropertiesPathAndName"

               // Create the properties file
               writeFile file: "$filePropertiesPathAndName", text: "$allParams"

               // Archive the properties file
               archiveArtifacts artifacts: "${fileproperties}"
               echo 'Completed --- Setup File Propeties'
            }
         }
      }
    } // end of stages
}
