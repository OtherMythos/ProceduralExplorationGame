import sys, json;

data = json.load(sys.stdin)

def findArtifact(name):
    for i in data["artifacts"]:
        if name in i["name"]:
            print(i["id"])
            break

findArtifact(sys.argv[1])
#print(data)