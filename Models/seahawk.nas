
# ==================================== timer stuff ===============================

# set the update period

UPDATE_PERIOD = 0.3;

# set the timer for the selected function

var registerTimer = func {

	settimer(arg[0], UPDATE_PERIOD);

} # end function 

# =============================== end timer stuff ===============================
# =============================== armament stuff ================================

var controls.trigger = func(v) setprop("/ai/submodels/trigger", v);


# =============================== Gear stuff ====================================

var caster_angle = props.globals.getNode("gear/gear/caster-angle-deg", 1);
var roll_speed = props.globals.getNode("gear/gear/rollspeed-ms", 1);
var wow = props.globals.getNode("gear/gear/wow", 1);
var timeratio = props.globals.getNode("gear/gear/timeratio", 1);
var caster_angle_damped = props.globals.getNode("gear/gear/caster-angle-deg-damped", 1);

caster_angle.setDoubleValue(0); 
roll_speed.setDoubleValue(0); 
timeratio.setDoubleValue(0.1); 
caster_angle_damped.setDoubleValue(0);
wow.setBoolValue(1); 

var angle_damp = 0;

var updateCasterAngle = func {
	var n = timeratio.getValue(); 
	var angle = caster_angle.getValue() ;
	var speed = roll_speed.getValue();
	var _wow = wow.getValue();

	if ( _wow ) {  
		n = (0.02 * speed) + 0.001;
	} else {
		n = 0.5;
	}

	angle_damp = ( angle * n) + (angle_damp * (1 - n));

	caster_angle_damped.setDoubleValue(angle_damp);
	timeratio.setDoubleValue(n); 

# print(sprintf("caster_angle_damped in=%0.5f, out=%0.5f", angle, angle_damp));

	settimer(updateCasterAngle, 0.1);

} #end func updateCasterAngle()

#fire it up
updateCasterAngle();

var tailwheel_lock = props.globals.getNode("/controls/gear/tailwheel-lock", 1);
var launchbar_state = props.globals.getNode("/gear/launchbar/state", 1);

var tailwheel_lock.setDoubleValue(1);
var launchbar_state.setValue("Disengaged");  

var updateTailwheelLock = func {
	var lock = tailwheel_lock.getValue(); 
	var state = launchbar_state.getValue() ;

	if ( state != "Disengaged" ) {   
		lock = 0;
	} else {
		lock = 1;
	}

	tailwheel_lock.setDoubleValue(lock);

#print("tail-wheel-lock " , lock , " state " , state);

} #end func updateTailwheelLock()

setlistener( launchbar_state , updateTailwheelLock );

# ======================================= end Gear stuff ============================

# ======================================= fuel tank stuff ===================================

# operate fuel cocks

var openCock=func{

	var cock=getprop("controls/engines/engine/fuel-cock/lever");

	if (cock < 1){
		cock = cock +1;
		setprop("controls/engines/engine/fuel-cock/lever",cock);
		adjustCock()
	}

}#end func

var closeCock=func{

	var cock = getprop("controls/engines/engine/fuel-cock/lever");

	if (cock > 0){
		cock = cock - 1;
		setprop("controls/engines/engine/fuel-cock/lever",cock);
		adjustCock()
	}

}#end func


# adjust fuel cocks

var adjustCock = func{

	var lever=getprop("controls/engines/engine/fuel-cock/lever");

	if (lever == 0){
		setprop("consumables/fuel/tank[0]/selected",0);
		setprop("consumables/fuel/tank[1]/selected",0);
		setprop("consumables/fuel/tank[2]/selected",0);
	}
	else{
		setprop("consumables/fuel/tank[0]/selected",1);
		setprop("consumables/fuel/tank[1]/selected",1);
		setprop("consumables/fuel/tank[2]/selected",0);
	}


}#end func

# tranfer fuel

fuelTrans = func {

	var amount = 0;
	var maxFlowRate = 1;

	if(getprop("/sim/freeze/fuel")) { return registerTimer(fuelTrans); }

	capacityFwd = getprop("consumables/fuel/tank[0]/capacity-gal_us");
	if(capacityFwd == nil) { capacityFwd = 0; }

	var levelFwd = getprop("consumables/fuel/tank[0]/level-gal_us");
	if(levelFwd == nil) { levelFwd = 0; }

	var levelSaddle = getprop("consumables/fuel/tank[2]/level-gal_us");
	if(levelSaddle == nil) { levelSaddle = 0; }

	var levelDropStbd = getprop("consumables/fuel/tank[3]/level-gal_us");
	if(levelDropStbd == nil) { levelDropStbd = 0; }

	var levelDropPort = getprop("consumables/fuel/tank[4]/level-gal_us");
	if(levelDropPort == nil) { levelDropPort = 0; }	

	if ( capacityFwd > levelFwd and levelDropStbd > 0){
		amount = capacityFwd - levelFwd;
		if (amount > levelDropStbd) {
			amount = levelDropStbd;
		}
		if (amount > maxFlowRate) {
			amount = maxFlowRate;
		}
		levelDropStbd = levelDropStbd - amount/2;
		levelDropPort = levelDropPort - amount/2;
		levelFwd = levelFwd + amount;
		setprop( "consumables/fuel/tank[3]/level-gal_us",levelDropStbd);
		setprop( "consumables/fuel/tank[4]/level-gal_us",levelDropPort);
		setprop( "consumables/fuel/tank[0]/level-gal_us",levelFwd);
	}

	if ( capacityFwd > levelFwd and levelSaddle > 0){
		amount = capacityFwd - levelFwd;
		if (amount > levelSaddle) {
			amount = levelSaddle;
		}
		if (amount > maxFlowRate) {
			amount = maxFlowRate;
		}
		levelSaddle = levelSaddle - amount;
		levelFwd = levelFwd + amount;
		setprop( "consumables/fuel/tank[2]/level-gal_us",levelSaddle);
		setprop( "consumables/fuel/tank[0]/level-gal_us",levelFwd);
	}

#print("Upper: ",levelSaddle, " Lower: ",levelFwd);
#print( " Amount: ",amount);

	registerTimer(fuelTrans);

} # end funtion fuelTrans    

# fire it up

registerTimer(fuelTrans);

# ========================== end fuel stuff ======================================


# =========================== hydraulic stuff =========================================

toggleAirbrakeLever = func{             #toggles the lever up-down

var lever = getprop("controls/flight/speedbrake-lever[0]"); 

lever = !lever;
setprop("controls/flight/speedbrake-lever",lever);

adjustFlaps();

} # end function 

setFlapLever = func{             #adjusts the lever up-down

var input = getprop("/controls/flight/flaps");
var lever = getprop("controls/flight/flaps-lever[0]");

setprop("controls/flight/flaps-lever[0]",input);

adjustFlaps();

} # end function 

setlistener( "controls/flight/flaps", setFlapLever);

adjustFlaps = func{

	var speedbrakelever = getprop("controls/flight/speedbrake-lever[0]");
	var flaplever = getprop("controls/flight/flaps-lever[0]");

	if (speedbrakelever == 1 and flaplever == 0) {
		setprop("/controls/flight/speedbrake-pos-norm",1);
		setprop("/controls/flight/flaps-pos-norm",0.36);
		return;
	} elsif (flaplever > 0){
		setprop("/controls/flight/speedbrake-pos-norm",0);
#setprop("/controls/flight/flaps-pos-norm", flaplever);
		return registerTimer(flapBlowin); 
	} elsif (speedbrakelever == 0 and flaplever == 0){
		setprop("/controls/flight/speedbrake-pos-norm",0);
		setprop("/controls/flight/flaps-pos-norm",0);
	}

} # end function 


flapBlowin = func{

	var flap = 0;

	var flaplever = getprop("controls/flight/flaps-lever");
	var airspeed = getprop("velocities/airspeed-kt");
	var flap_pos = getprop("surface-positions/flap-pos-norm");

#print("lever: " , flaplever );

	if (flaplever <= 0.36){
		setprop("controls/flight/flaps-pos-norm", flaplever);
		return;      
	} elsif (airspeed < 250) { 
		setprop("controls/flight/flaps-pos-norm" , flaplever);    # increase the flap
			return registerTimer(flapBlowin);                         # run the timer                
	} elsif (airspeed >= 250 and airspeed <= 350) {
		flap = -0.0064 * airspeed + 2.6;
#print ("flap: ", flap); 
		if(flap_pos < (flap - 0.05)){
			setprop("controls/flight/flaps-pos-norm" , flap_pos + 0.05); # flap partially blown in
		} 
		if(flap_pos > (flap + 0.05)){
			setprop("controls/flight/flaps-pos-norm" , flap_pos - 0.05); # flap partially blown in 
		}
		return registerTimer(flapBlowin);					# run the timer
	} elsif (airspeed > 350) {
		flap = 0.36;
		if(flap_pos > flap){
			setprop("controls/flight/flaps-pos-norm" , flap_pos - 0.05); # flap fully blown in 
		} 
		return registerTimer(flapBlowin);                  # run timer
		} elsif ( lever[0] == 0 ) {
			setprop("controls/flight/flaps-pos-norm" , 0);
		}


} # end function

# =============================== end flap stuff =========================================


# =============================== Pilot G stuff======================================

var pilot_g = props.globals.getNode("accelerations/pilot-g", 1);
var g_timeratio = props.globals.getNode("accelerations/timeratio", 1);
var pilot_g_damped = props.globals.getNode("accelerations/pilot-g-damped", 1);

pilot_g.setDoubleValue(0);
pilot_g_damped.setDoubleValue(0); 
g_timeratio.setDoubleValue(0.0075); 

var g_damp = 0;

updatePilotG = func {
	var n = g_timeratio.getValue(); 
	var g = pilot_g.getValue() ;

	g_damp = ( g * n) + (g_damp * (1 - n));

	pilot_g_damped.setDoubleValue(g_damp);

# print(sprintf("pilot_g_damped in=%0.5f, out=%0.5f", g, g_damp));

	settimer(updatePilotG, 0);

} #end updatePilotG()

updatePilotG();

#============================== head movement stuff =============================
# headshake - this is a modification of the original work by Josh Babcock

# Define some stuff with global scope

xConfigNode = '';
yConfigNode = '';
zConfigNode = '';

xAccelNode = '';
yAccelNode = '';
zAccelNode = '';

var xDivergence_damp = 0;
var yDivergence_damp = 0;
var zDivergence_damp = 0;

var last_xDivergence = 0;
var last_yDivergence = 0;
var last_zDivergence = 0;

# Make sure that some vital data exists and set some default values
enabledNode = props.globals.getNode("/sim/headshake/enabled", 1);
enabledNode.setBoolValue(1);

xMaxNode = props.globals.getNode("/sim/headshake/x-max-m",1);
xMaxNode.setDoubleValue( 0.025 );

xMinNode = props.globals.getNode("/sim/headshake/x-min-m",1);
xMinNode.setDoubleValue( -0.01 );

yMaxNode = props.globals.getNode("/sim/headshake/y-max-m",1);
yMaxNode.setDoubleValue( 0.01 );

yMinNode = props.globals.getNode("/sim/headshake/y-min-m",1);
yMinNode.setDoubleValue( -0.01 );

zMaxNode = props.globals.getNode("/sim/headshake/z-max-m",1);
zMaxNode.setDoubleValue( 0.01 );

zMinNode = props.globals.getNode("/sim/headshake/z-min-m",1);
zMinNode.setDoubleValue( -0.03 );

view_number_Node = props.globals.getNode("/sim/current-view/view-number",1);
view_number_Node.setDoubleValue( 0 );

time_ratio_Node = props.globals.getNode("/sim/headshake/time-ratio",1);
time_ratio_Node.setDoubleValue( 0.003 );

seat_vertical_adjust_Node = props.globals.getNode("/controls/seat/vertical-adjust",1);
seat_vertical_adjust_Node.setDoubleValue( 0 );

xThreasholdNode = props.globals.getNode("/sim/headshake/x-threashold-g",1);
xThreasholdNode.setDoubleValue( 0.5 );

yThreasholdNode = props.globals.getNode("/sim/headshake/y-threashold-g",1);
yThreasholdNode.setDoubleValue( 0.5 );

zThreasholdNode = props.globals.getNode("/sim/headshake/z-threashold-g",1);
zThreasholdNode.setDoubleValue( 0.5 );

# We will use these later
xConfigNode = props.globals.getNode("/sim/view/config/z-offset-m");
yConfigNode = props.globals.getNode("/sim/view/config/x-offset-m");
zConfigNode = props.globals.getNode("/sim/view/config/y-offset-m");

xAccelNode = props.globals.getNode("/accelerations/pilot/x-accel-fps_sec",1);
xAccelNode.setDoubleValue( 0 );
yAccelNode = props.globals.getNode("/accelerations/pilot/y-accel-fps_sec",1);
yAccelNode.setDoubleValue( 0 );
zAccelNode = props.globals.getNode("/accelerations/pilot/z-accel-fps_sec",1);
zAccelNode.setDoubleValue(-32 );


headShake = func {

# First, we don't shake outside the vehicle. Inside, we boogie down.
# There are two coordinate systems here, one used for accelerations, and one used for the viewpoint.
# We will be using the one for accelerations.
	var enabled = enabledNode.getValue();
	var view_number= view_number_Node.getValue();
	var n = g_timeratio.getValue(); 
	var seat_vertical_adjust = seat_vertical_adjust_Node.getValue();


	if ( (enabled) and ( view_number == 0)) {

		var xConfig = xConfigNode.getValue();
		var yConfig = yConfigNode.getValue();
		var zConfig = zConfigNode.getValue();

		var xMax = xMaxNode.getValue();
		var xMin = xMinNode.getValue();
		var yMax = yMaxNode.getValue();
		var yMin = yMinNode.getValue();
		var zMax = zMaxNode.getValue();
		var zMin = zMinNode.getValue();

#work in G, not fps/s
		var xAccel = xAccelNode.getValue()/32;
		var yAccel = yAccelNode.getValue()/32;
		var zAccel = (zAccelNode.getValue() + 32)/32; # We aren't counting gravity

			var xThreashold =  xThreasholdNode.getValue();
		var yThreashold =  yThreasholdNode.getValue();
		var zThreashold =  zThreasholdNode.getValue();

# Set viewpoint divergence and clamp
# Note that each dimension has it's own special ratio and +X is clamped at 1cm
# to simulate a headrest.

		if (xAccel < -1) {
			xDivergence = ((( -0.0506 * xAccel ) - ( 0.538 )) * xAccel - ( 0.9915 )) * xAccel - 0.52;
		} elsif (xAccel > 1) {
			xDivergence = ((( -0.0387 * xAccel ) + ( 0.4157 )) * xAccel - ( 0.8448 )) * xAccel + 0.475;
		}else {
			xDivergence = 0;
		}
#        setprop("/sim/current-view/z-offset-m", (xConfig + xDivergence));

		if (yAccel < -0.5) {
			yDivergence = ((( -0.013 * yAccel ) - ( 0.125 )) * yAccel - (  0.1202 )) * yAccel - 0.0272;
		} elsif (yAccel > 0.5) {
			yDivergence = ((( -0.013 * yAccel ) + ( 0.125 )) * yAccel - (  0.1202 )) * yAccel + 0.0272;
		}else {
			yDivergence = 0;
		}
#        setprop("/sim/current-view/x-offset-m", (yConfig + yDivergence));

		if (zAccel < -1) {
			zDivergence = ((( -0.0506 * zAccel ) - ( 0.538 )) * zAccel - ( 0.9915 )) * zAccel - 0.52;
		} elsif (zAccel > 1) {
			zDivergence = ((( -0.0387 * zAccel ) + ( 0.4157 )) * zAccel - ( 0.8448 )) * zAccel + 0.475;
		} else {
			zDivergence = 0;
		}


		xDivergence_total = ( xDivergence * 0.25 ) + ( zDivergence * 0.25 );
		if (xDivergence_total > xMax){xDivergence_total = xMax;}
		if (xDivergence_total < xMin){xDivergence_total = xMin;}

		if (abs(last_xDivergence - xDivergence_total) <= xThreashold){
			xDivergence_damp = ( xDivergence_total * n) + ( xDivergence_damp * (1 - n));
#	print ("x low pass");
		} else {
			xDivergence_damp = xDivergence_total;
#	print ("x high pass");
		}

		last_xDivergence = xDivergence_damp;

#print (sprintf("x total=%0.5f, x min=%0.5f, x div damped=%0.5f", xDivergence_total, xMin , xDivergence_damp));	

		yDivergence_total = yDivergence;
		if (yDivergence_total >= yMax){yDivergence_total = yMax;}
		if (yDivergence_total <= yMin){yDivergence_total = yMin;}

		if (abs(last_yDivergence - yDivergence_total) <= yThreashold){
			yDivergence_damp = ( yDivergence_total * n) + ( yDivergence_damp * (1 - n));
# 	print ("y low pass");
		} else {
			yDivergence_damp = yDivergence_total;
#	print ("y high pass");
		}

		last_yDivergence = yDivergence_damp;

#print (sprintf("y=%0.5f, y total=%0.5f, y min=%0.5f, y div damped=%0.5f",yDivergence, yDivergence_total, yMin , yDivergence_damp));

		zDivergence_total =  xDivergence + zDivergence;
		if (zDivergence_total >= zMax){zDivergence_total = zMax;}
		if (zDivergence_total <= zMin){zDivergence_total = zMin;}

		if (abs(last_zDivergence - zDivergence_total) <= zThreashold){ 
			zDivergence_damp = ( zDivergence_total * n) + ( zDivergence_damp * (1 - n));
#        print ("z low pass");
		} else {
			zDivergence_damp = zDivergence_total;
#	print ("z high pass");
		}

		last_zDivergence = zDivergence_damp;

#print (sprintf("z total=%0.5f, z min=%0.5f, z div damped=%0.5f", zDivergence_total, zMin , zDivergence_damp));

		setprop("/sim/current-view/z-offset-m", xConfig + xDivergence_damp );
		setprop("/sim/current-view/x-offset-m", yConfig + yDivergence_damp );
		setprop("/sim/current-view/y-offset-m", zConfig + zDivergence_damp + seat_vertical_adjust );
	}

	settimer(headShake,0 );

} #end func

headShake();
# ======================================= end Pilot G stuff ============================

# ======================================= jet exhaust ========================

speed_node = props.globals.getNode("velocities/uBody-fps", 1);
exhaust_node = props.globals.getNode("sim/ai/aircraft/exhaust", 1);

exhaust_node.setBoolValue(1) ;

updateExhaustState = func {
	var speed = speed_node.getValue(); 
	var exhaust = exhaust_node.getValue() ;

	if (speed == nil) {return;}
	if (speed >= 90) {   
		exhaust = 0;
	} else {
		exhaust = 1;
	}

	exhaust_node.setBoolValue(exhaust) ;

#        print("exhaust " , exhaust);

#        settimer(updateExhaustState, 0);

} #end func updateExhaustState()

#settimer(updateExhaustState,0);

# ================================== Steering =================================================

aircraft.steering.init();

#================================== Droptanks ================================
print("droptanks starting");
var droptank_node = props.globals.getNode("sim/ai/aircraft/impact/droptank", 1);

var droptanks = func {
	var droptank = droptank_node.getValue();
	var node = props.globals.getNode(cmdarg().getValue(), 1);
	print (" droptank ", droptank, " lon " , node.getNode("impact/longitude-deg").getValue(),);
	geo.put_model("Aircraft/seahawk/Models/droptank.xml",
		node.getNode("impact/latitude-deg").getValue(),
		node.getNode("impact/longitude-deg").getValue(),
		node.getNode("impact/elevation-m").getValue()+ 0.25,
		node.getNode("impact/heading-deg").getValue(),
		0,
		0
		);
}

setlistener( "sim/ai/aircraft/impact/droptank", droptanks);

print("droptanks running");

# end 
