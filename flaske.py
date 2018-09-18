
import json
import pymysql
import math
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello_world():
	db = pymysql.connect(host='',user='', password='', port=3306, db='')
	#pos#postcode in table addressgeo must less than table house

	cursor=db.cursor()

	#
	sql = "SELECT postcode, json,average,amount,lat,lng FROM .addressgeo where postcode=npostcode and memo>=1 and replace(postcode,' ','') not in (select postcode from postcodeF)"

	cursor.execute(sql)
	results = cursor.fetchall()

	google = {}
	google["type"] = "FeatureCollection"
	features = []
	i = 0
	for row in results:
	    #print(row)
	    i = i + 1
	    a = str(row[0]).replace(' ', '')
	    b = row[1]
	    c = json.loads(b)
	    #lname = c["results"][0]["address_components"][0]["long_name"].replace(' ', '')
	    arr = []
	    dic = {}
	    #if (a == lname):
	        # print(c)
	        # if("viewport" in c["results"][0]["geometry"]):
	        # northeast=c["results"][0]["geometry"]["bounds"]["northeast"]
	        # southwest=c["results"][0]["geometry"]["bounds"]["southwest"]
	        # northeast=c["results"][0]["geometry"]["viewport"]["northeast"]
	        # southwest=c["results"][0]["geometry"]["viewport"]["southwest"]
	        # arr.append([southwest["lng"], southwest["lat"]])
	        # arr.append([northeast["lng"], southwest["lat"]])
	        # arr.append([northeast["lng"], northeast["lat"]])
	        # arr.append([southwest["lng"], northeast["lat"]])
	        # arr.append([southwest["lng"], southwest["lat"]])

	    #loc_lng = c["results"][0]["geometry"]["location"]["lng"]
	    loc_lng = float(row[5])
	    loc_lat = float(row[4])
	    #loc_lat = c["results"][0]["geometry"]["location"]["lat"]
	    xs = row[3]

	    arr.append([loc_lng + 0.0001 * math.sqrt((xs) / 2), loc_lat - 0.0001 * math.sqrt((xs) / 2)])
	    arr.append([loc_lng + 0.0001 * math.sqrt((xs) / 2), loc_lat + 0.0001 * math.sqrt((xs) / 2)])
	    arr.append([loc_lng - 0.0001 * math.sqrt((xs) / 2), loc_lat + 0.0001 * math.sqrt((xs) / 2)])
	    arr.append([loc_lng - 0.0001 * math.sqrt((xs) / 2), loc_lat - 0.0001 * math.sqrt((xs) / 2)])
	    arr.append([loc_lng + 0.0001 * math.sqrt((xs) / 2), loc_lat - 0.0001 * math.sqrt((xs) / 2)])

	    dic["type"] = "Feature"

	    dic["properties"] = {"postcode": a, "average": row[2], "amount": row[3]}
	    dic["geometry"] = {"type": "Polygon", "coordinates": [arr]}

	    features.append(dic)

	google["features"] = features
	#print(json.dumps(google))
	#print("count " + str(i))
	return (json.dumps(google))
app.run(host='0.0.0.0', port= 8081)
