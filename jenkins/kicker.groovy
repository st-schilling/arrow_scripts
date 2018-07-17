import groovy.json.JsonSlurper

String getDay() { ['date', '+%u'].execute().text.trim()}
String getDevices() { ['curl', '-s', 'PLACEHOLDER'].execute().text }

def jsonParse(def json) { new groovy.json.JsonSlurperClassic().parseText(json) }

node {
  try {
    def json = jsonParse(getDevices())
    for(int i = 0; i < json.size(); i++) {
			echo "${json[i].device} is scheduled to be built today."
			build job: 'builder', parameters: [
			string(name: 'DEVICE', value: (json[i].device == null) ? "lolwut" : json[i].device),
			string(name: 'BUILD_TYPE', value: (json[i].build_type == null) ? "userdebug" : json[i].build_type)
			], propagate: false, wait: false
			sleep 5
    }
  } catch (e) {
    currentBuild.result = "FAILED"
    throw e
  }
}
