'''
How to use:
1. Download the Groupie google sheet's Instance data, and achievement data sheets as TSV files
2. Leave them as the default names they were downloaded as
3. Place these two tsv files in the same directory as tsvtolua.py
4. run this python file with python 3.0 or higher
5. The data for the instances and achievments tables will be outputted to INSTANCEDATA.txt and ACHIEVEMENTDATA.txt
6. replace the data in globals.lua
ACHIEVEMENTDATA.txt --> addon.groupieAchievementPriorities
INSTANCEDATA.txt --> addon.groupieInstanceData
'''


# INSTANCE DATA
with open("Groupie - Instance & Achievment Data - Instances.tsv") as myfile:
    data = myfile.read().split('\n')


outfile = open("INSTANCEDATA.txt", "w")
for i in data:
    line = i.replace('’', "\'").split('\t')
    if line[0] == "Active":
        continue
    active = "false"
    if line[0] == "Yes":
        active = "true"
    outfile.write("[\""+line[9]+"\"] = { Active = "+active+", Expac = \""+line[1]+"\", InstanceType = \""+line[2] +
                  "\", InstanceID = "+line[4]+", MinLevel = "
                  + line[5]+", MaxLevel = "+line[6]+", GroupSize = "+line[7]+", Order = "+line[3]+", Icon = \""+line[10]+".tga\", ActivityID = "+line[11]+"},\n")

outfile.close()


# ACHIEVEMENT DATA
with open("Groupie - Instance & Achievment Data - Achievements.tsv") as myfile:
    data = myfile.read().split('\n')


outfile = open("ACHIEVEMENTDATA.txt", "w")
previnstance = ""
for i in data:
    line = i.replace('’', "\'").split('\t')
    instance = line[0]
    if instance == "Instance":
        continue
    prio = line[1]
    achieveid = line[2]
    if instance != previnstance and previnstance != "":
        outfile.write("},\n")
    if instance != previnstance:
        outfile.write("[\""+instance+"\"] = {\n")
    outfile.write("\t["+prio+"] = "+achieveid+",\n")
    previnstance = instance
outfile.write("},")
outfile.close()