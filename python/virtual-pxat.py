import json
import math
import random
import requests
import time
from datetime import datetime

# Path co-ordinates
PATH = [
    51.52524153701639, -0.14578144487664885,
    51.528901886027526, -0.145833975553682,
    51.53047051695207, -0.14604409826181455,
    51.535274112950006, -0.14809279466610697,
    51.535666220857244, -0.14704218112544418,
    51.536254376384754, -0.14683205841731164,
    51.53677717491779, -0.14630675164698026,
    51.53860692249481, -0.14394287118048904,
    51.538900982208645, -0.14268213493169374,
    51.53961978684388, -0.14184164409916353,
    51.540534612687544, -0.13995053972597055,
    51.535372140243474, -0.13543290150112067,
    51.53563354532733, -0.13306902103462948,
    51.535470167325855, -0.13254371426429806,
    51.53432650489558, -0.12970705770450863,
    51.5330847817218, -0.12839379077868016,
    51.531581597823156, -0.12723811588395115,
    51.529097967848834, -0.1262400330203215,
    51.52733866018528, -0.1308029187566903,
    51.52509585527532, -0.13814144237246997,
    51.52309325753665, -0.13663940537508817,
    51.520075843965266, -0.13389282343701858,
    51.51809973028278, -0.13925724128481076,
    51.51740539971483, -0.1427762993929624,
    51.51540246377176, -0.15449218797254044,
    51.5151353989913, -0.15659503976887498,
    51.52175814344872, -0.15964202910642092,
    51.52218538421565, -0.1574533466245217,
    51.52418802188015, -0.1584833148512978,
    51.525790068600365, -0.16144447350327912,
    51.52728526135223, -0.16436271681247805,
    51.52984833469578, -0.16758136752115332,
    51.53005692403693, -0.16829977752833516,
    51.53031865504123, -0.16780893723268292,
    51.53090754429931, -0.1673180969370307,
    51.53371030705962, -0.16545816778579234,
    51.53452989173601, -0.16451296345940497,
    51.53497531200122, -0.16362504424370783,
    51.53410228418074, -0.1627371250280107,
    51.53155437255845, -0.1650858145663064,
    51.53118019170962, -0.1652576698983768,
    51.529523068123666, -0.1647134613468205,
    51.529523068123666, -0.16477074645751064,
    51.52754513197904, -0.16173463559093323,
    51.52642248134677, -0.15995879715953892,
    51.52490775011727, -0.15875580983504597,
    51.52366028656271, -0.15557648619174322,
    51.52403452921743, -0.1529413710999968]
 
# Geofence setting
holmes = [51.52350754709937, -0.15798841133320837]
holmes_radius = 50.0

# Data recorders
current_speed = 5 # m/s
current_index = 0
current_coords = [PATH[current_index], PATH[current_index + 1]]
current_alerts = []
current_temp = 22.45

is_stopped = False
in_geofence = False
in_temp_alert = False

# App-level parameters
device_id = "UV1a2b3c4d5e6f7a8b9c0d"
report_period = 180
temp_min = 10.0
temp_max = 40.0
gnss_accuracy = 3.01
geofence_enabled = True
geofence_coords = holmes
geofence_radius = holmes_radius

# Constants
PI = 3.141257
LAT = 0
LNG = 1
LOSANT_URL = "https://triggers.losant.com/webhooks/y6OotJYqTuj1SpGfcu_AglLNQzvHHjdd7SAkW8jG"

# Functions
def sign(x):
    if x == 0:
        return 0
    if x < 0:
        return -1
    return 1
    
def update_temp():
    global current_temp
    global current_alerts
    global in_temp_alert
        
    if d100() < 90:
        current_temp += random.uniform(-1, 1.0)
    else:
        current_temp += random.uniform(-10, 10.0)
    
    if current_temp < temp_min and not in_temp_alert:
        current_alerts.append("temperatureLow")
        in_temp_alert = True
        
    if current_temp >= temp_max and not in_temp_alert:
        current_alerts.append("temperatureHigh")
        in_temp_alert = True
        
    if in_temp_alert and temp_min <= current_temp < temp_max:
        in_temp_alert = False

def check_geofence():
    global in_geofence
    global current_alerts
    
    if not geofence_enabled:
        return
    
    state = is_in_geofence()
    
    if not in_geofence and state:
        in_geofence = True
        current_alerts.append("geofenceEntered")
    
    if in_geofence and not state:
        in_geofence = False
        current_alerts.append("geofenceExited")
      
    return

def is_in_geofence():
    global in_geofence

    '''
                    _____GeofenceZone
                   /      \
                  /__     R\    dist           __Location
                 |/\ \  .---|-----------------/- \
                 |\__/      |                 \_\/accuracy (radius)
                  \ Location/
                   \______ /
                  in zone                     not in zone
       (location with accuracy radius      (location with accuracy radius
        entirely in geofence zone)          entirely not in geofence zone)
    '''
    inside = False
    dist = great_circle_distance()
    
    if dist > geofence_radius:
        dist_minus_accuracy = dist - gnss_accuracy
        if dist_minus_accuracy > geofence_radius and in_geofence:
            # Moved outside the zone
            inside = False
        else:
            inside = in_geofence
    else:
        dist_plus_accuracy = dist + gnss_accuracy
        if dist_plus_accuracy <= geofence_radius and (not in_geofence):
            # Entered the zone
            inside = True
        else:
            inside = in_geofence 
    return inside

def great_circle_distance():
    distance = 0.0
    d_lat  = math.fabs(geofence_coords[LAT] - current_coords[LAT]) * PI / 180.0
    d_long = math.fabs(geofence_coords[LNG] - current_coords[LNG]) * PI / 180.0

    '''
       Select the shortest arc:
        -180___180
           / | \
      west|  |  |east
           \_|_/
      Earth 0 longitude
    '''
    if d_long > PI:
        d_long = 2 * PI - d_long

    d_sigma = math.pow(math.sin(0.5 * d_lat), 2)
    d_sigma += math.cos(geofence_coords[LAT] * PI / 180.0) * math.cos(current_coords[LAT] * PI / 180.0) * math.pow(math.sin(0.5 * d_long), 2)
    d_sigma = 2 * math.asin(math.sqrt(d_sigma))

    # Actual arc length on a sphere of radius r (mean Earth radius)
    distance = 6371009.0 * d_sigma
    return distance

def check_halt():
    global is_stopped
    global pause_time
    
    if not is_stopped:
        if d100() > 95:
            pause_time = random.randint(60, 300) # 1-5 mins
            is_stopped = True
            current_alerts.append("motionStopped")
    else:
        pause_time -= 1
        if pause_time == 0:
            is_stopped = False
            current_alerts.append("motionStarted")
        
def make_report():
    """
    {"trackerId":"UV6dc3ab93b84c5b4f434a7b9aba6e0ef2","timestamp":1716382889,"status":{"inMotion":true},"location":{"timestamp":3026988324,"type":"gnss","accuracy":15.84200001,"lng":-0.12302921,"lat":51.55076218},"sensors":{"temperature":24.75,"batteryLevel":100},"alerts":[]}
    """
    a = {"trackerId": device_id,
         "timestamp": math.ceil((datetime.now() - datetime(1970, 1, 1)).total_seconds()),
         "status":
            {"inMotion": (not is_stopped),
             "inGeofence": in_geofence},
         "location":
            {"timestamp": math.ceil((datetime.now() - datetime(1970, 1, 1)).total_seconds()),
             "type":"gnss",
             "accuracy": gnss_accuracy,
             "lng":current_coords[LAT],
             "lat":current_coords[LNG]},
          "sensors":
            {"temperature":current_temp,
             "batteryLevel":100},
          "alerts":current_alerts
        }
    return a, json.dumps(a)

def send_report(report):
    response = requests.post(LOSANT_URL, json=report)
    if response.status_code != 200:
        print("[ERROR] Failed to post report")
        
def d100():
    return random.randint(0, 100)
    
# Runtime start
if __name__ == '__main__':
    
    # Loop control
    pause_time = 0
    report_count = 0
    loop_limit = 2
    print_flag = True
    
    random.seed()
    
    # Travel the path
    while True:
        start_time = time.time()
        
        # Check for alerts: report if there are any
        if len(current_alerts) > 0:
            alert_json, alert_text = make_report()
            #send_report(alert_json)
            print("ALERT",alert_json)
            current_alerts = []
        else:
            # Issues a report every `report_period` seconds
            report_count += 1
            if report_count > report_period:
                report_json, report_text = make_report()
                #send_report(report_json)
                print(report_text)
                report_count = 0
        
        # Is the device moving?
        if not is_stopped:
            # Have we reached the next point on the path?
            next_index = current_index + 2
            if next_index >= len(PATH):
                # Reached the end
                next_index = 0
                print("-------------------------------------------------------")
                loop_limit -= 1
                # After `loop_limit` traversals, bail
                if loop_limit == 0:
                    break
            
            # Get trakcer's location and the location of the next point on the PATH             
            start_lat = PATH[current_index]
            start_lng = PATH[current_index + 1]
            end_lat = PATH[next_index]
            end_lng = PATH[next_index + 1]
            delta_lat = sign(end_lat - start_lat)
            delta_lng = sign(end_lng - start_lng)
            
            if print_flag:
                print("+++++++++++++++++++++++++++++++++++++++++++++++++++++++")          
                print(f"FROM {start_lat:.8f},{start_lng:.8f} TO {end_lat:.8f},{end_lng:.8f}") 
                print_flag = False
            
            new_coords = current_coords
            
            if delta_lat != 0 and delta_lng != 0:
                angle = math.atan(math.fabs(end_lng - start_lng) / math.fabs(end_lat - start_lat))
            elif delta_lat == 0 and delta_lng != 0:
                angle = PI / 2
            elif delta_lat != 0 and delta_lng == 0:
                angle = 0
            
            speed = 0.0000449 * (current_speed / 5)
            
            if delta_lat != 0:
                new_coords[LAT] = current_coords[LAT] + (delta_lat * speed * math.cos(angle))
            else:
                new_coords[LAT] = current_coords[LAT]
            
            if delta_lng != 0:
                new_coords[LNG] = current_coords[LNG] + (delta_lng * speed * math.sin(angle))
            else:
                 new_coords[LNG] = current_coords[LNG]
            
            if (delta_lat == 1 and new_coords[LAT] >= end_lat) or (delta_lat == -1 and new_coords[LAT] <= end_lat):
                new_coords[LAT] = end_lat
            
            if (delta_lng == 1 and new_coords[LNG] >= end_lng) or (delta_lng == -1 and new_coords[LNG] <= end_lng):
                new_coords[LNG] = end_lng
            
            if new_coords[LAT] == end_lat and new_coords[LNG] == end_lng:
                current_index = next_index
                print_flag = True
                
            current_coords = new_coords
            print(f"TRACKER MOVING AT {current_coords[LAT]:.8f},{current_coords[LNG]:.8f}, TEMP {current_temp:.2f} C")
        else:
            print(f"TRACKER PAUSED AT {current_coords[LAT]:.8f},{current_coords[LNG]:.8f}, TEMP {current_temp:.2f} C")
        
        # Update 'sensor', check for events
        update_temp()
        check_geofence()
        check_halt()
        
        # Delay for 1s - duration of code above
        pause_period = 1 - time.time() - start_time
        if pause_period < 0:
            pause_period = 1
        time.sleep(pause_period)
        
