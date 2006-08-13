
# ==================================== timer stuff ===========================================

# set the update period

UPDATE_PERIOD = 0.3;

# set the timer for the selected function

registerTimer = func {
	
    settimer(arg[0], UPDATE_PERIOD);

} # end function 

# =============================== end timer stuff ===========================================

# =============================== Gear stuff======================================

caster_angle = props.globals.getNode("gear/gear/caster-angle-deg", 1);
roll_speed = props.globals.getNode("gear/gear/rollspeed-ms", 1);
wow = props.globals.getNode("gear/gear/wow", 1);
timeratio = props.globals.getNode("gear/gear/timeratio", 1);
caster_angle_damped = props.globals.getNode("gear/gear/caster-angle-deg-damped", 1);

caster_angle.setDoubleValue(0); 
roll_speed.setDoubleValue(0); 
timeratio.setDoubleValue(0.1); 
caster_angle_damped.setDoubleValue(0);
wow.setBoolValue(1); 

angle_damp = 0;

updateCasterAngle = func {
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

tailwheel_lock = props.globals.getNode("/controls/gear/tailwheel-lock", 1);
launchbar_state = props.globals.getNode("/gear/launchbar/state", 1);

tailwheel_lock.setDoubleValue(1);
launchbar_state.setValue("Disengaged");  

updateTailwheelLock = func {
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

openCock=func{

    cock=getprop("controls/engines/engine/fuel-cock/lever");
   
    if (cock < 1){
	    cock = cock +1;
		setprop("controls/engines/engine/fuel-cock/lever",cock);
		adjustCock()
		}
        
}#end func

closeCock=func{

    cock=getprop("controls/engines/engine/fuel-cock/lever");
   
    if (cock > 0){
	    cock = cock - 1;
		setprop("controls/engines/engine/fuel-cock/lever",cock);
		adjustCock()
		}
        
}#end func


# adjust fuel cocks

adjustCock=func{

    lever=getprop("controls/engines/engine/fuel-cock/lever");
    
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
    
    amount = 0;

    
    if(getprop("/sim/freeze/fuel")) { return registerTimer(fuelTrans); }
    
    capacityFwd = getprop("consumables/fuel/tank[0]/capacity-gal_us");
    if(capacityFwd == nil) { capacityFwd = 0; }
    
    levelFwd = getprop("consumables/fuel/tank[0]/level-gal_us");
    if(levelFwd == nil) { levelFwd = 0; }
    
    levelSaddle = getprop("consumables/fuel/tank[2]/level-gal_us");
    if(levelSaddle == nil) { levelSaddle = 0; }
    
    if ( capacityFwd > levelFwd and levelSaddle > 0){
        amount = capacityFwd - levelFwd;
        if (amount > levelSaddle) {amount = levelSaddle;}
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

toggleAirbrake = func{             #toggles the lever up-down
	
	lever=[0,1];
	
	lever[0]= getprop("controls/flight/speedbrake-lever[0]"); 
	lever[1]= getprop("controls/flight/flaps-lever[0]"); 
		
#	print ("lever in: ", lever[0], lever[1]);
	
	lever[0] = !lever[0];
  
	setprop("controls/flight/speedbrake-lever[0]",lever[0]);
	
	#print ("lever out: ", lever[0],lever[1]);	
			
} # end function 

adjustFlaps = func{             #adjusts the lever up-down
	
	up = arg[0];
	lever=[0,1];
	
	lever[0]= getprop("controls/flight/speedbrake-lever[0]"); 
	lever[1]= getprop("controls/flight/flaps-lever[0]"); 
		
#print ("lever in: ", up, lever[0],lever[1]);
	
	if (up){
		if (lever[1] == 0){
			lever[1] = 0.3;
		}	elsif (lever[1] == 0.3){
			lever[1] = 1;
			}
		} elsif (!up){
			if (lever[1] == 1){
				lever[1] = 0.3;
			} elsif (lever[1] == 0.3){
					lever[1] = 0;
				}
			}
	
	setprop("controls/flight/flaps-lever[0]",lever[1]);
#print ("lever out: ", lever[0],lever[1]);	
	registerTimer (flapBlowin);
			
} # end function 
	
	
#	if (lever[0] == 1 and lever[1] == 0) 
#	 	{ registerTimer (flapBlowin)}   # run the timer 
#		
#	if (lever[0] == -1 and lever[1] != 0) 
#	 	{ registerTimer (wheelsMove)}   # run the timer                    
	    

flapBlowin = func{
  
	flap = 0;
	lever=[0,1];
	
  lever[0] = getprop("controls/flight/speedbrake-lever[0]");
	lever[1] = getprop("controls/flight/flaps-lever[0]");
	airspeed = getprop("velocities/airspeed-kt");
	flap_pos = getprop("surface-positions/flap-pos-norm");
	 
	# print("lever: " , lever[0] , " " , lever[1] ," airspeed (kts): " , airspeed , " flap pos: " , flap_pos);
	 
	if (lever[0] == 1 and lever[1] == 0) {
			setprop("/controls/flight/speedbrake",1);
			setprop( "/controls/flight/flaps",0.3);
			return registerTimer(flapBlowin); 
		} elsif (lever[0] == 0 and lever[1] == 0){
			setprop("/controls/flight/speedbrake",0);
			setprop( "/controls/flight/flaps",0);
			return registerTimer(flapBlowin); 
		} elsif (lever[1] > 0){
			setprop("/controls/flight/speedbrake",0);
		}
			
		if (lever[1] == 0.3){
			setprop("controls/flight/flaps", 0.3);
			return registerTimer(flapBlowin);      
		} elsif (lever[1] == 1 and airspeed < 250) { 
			setprop("controls/flight/flaps" , 1);    # increase the flap
			return registerTimer(flapBlowin);                     # run the timer                
        } elsif (lever[1] == 1 and airspeed >= 250 and airspeed <= 350) {
            flap = -0.007 * airspeed + 2.75;
            #print ("flap: ", flap); 
            if(flap_pos < (flap - 0.05)){
            	setprop("controls/flight/flaps" , flap_pos + 0.05); # flap partially blown in
            } 
			if(flap_pos > (flap + 0.05)){
            	setprop("controls/flight/flaps" , flap_pos - 0.05); # flap partially blown in 
			}
			return registerTimer(flapBlowin);					# run the timer
		} elsif (lever[1] == 1 and airspeed > 350) {
            flap = 0.3;
            if(flap_pos > flap){
            	setprop("controls/flight/flaps" , flap_pos - 0.05); # flap fully blown in 
			} 
		    return registerTimer(flapBlowin);                  # run timer
		} elsif ( lever[0] == 0 and lever[1] == 0) {
			setprop("controls/flight/flaps" , 0);
		}
		
	 	
} # end function

# =============================== end flap stuff =========================================


# =============================== Pilot G stuff======================================

pilot_g = props.globals.getNode("accelerations/pilot-g", 1);
g_timeratio = props.globals.getNode("accelerations/timeratio", 1);
pilot_g_damped = props.globals.getNode("accelerations/pilot-g-damped", 1);

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

# ================================= view management ==============================

var cockpit_view = nil;
setlistener("/sim/current-view/view-number", func { cockpit_view = (cmdarg().getValue() == 0) }, 1);

var managed_view = nil;
setlistener("/sim/model/sea-vixen/managed-view", func { managed_view = cmdarg().getBoolValue() }, 1);

var headingN = props.globals.getNode("orientation/heading-deg");
var pitchN = props.globals.getNode("orientation/pitch-deg");
var rollN = props.globals.getNode("orientation/roll-deg");
var pilot_azN = props.globals.getNode("accelerations/pilot/z-accel-fps_sec");

sin = func(a) { math.sin(a * math.pi / 180.0) }
cos = func(a) { math.cos(a * math.pi / 180.0) }

ViewAxis = {
	new : func(prop) {
		var m = { parents : [ViewAxis] };
		m.prop = props.globals.getNode(prop, 0);
		m.reset();
		return m;
	},
	reset : func {
		me.applied_offset = 0;
	},
	input : func {
		die("ViewAxis.input() is pure virtual");
	},
	apply : func {
		var v = me.prop.getValue() - me.applied_offset;
		me.applied_offset = me.input();
		me.prop.setDoubleValue(v + me.applied_offset);
	},
	add_offset : func {
		me.prop.setValue(me.prop.getValue() + me.applied_offset);
	},
};


ViewManager = {
	new : func {
		var m = { parents : [ViewManager] };
		m.heading = ViewAxis.new("sim/current-view/goal-heading-offset-deg");
		m.pitch = ViewAxis.new("sim/current-view/goal-pitch-offset-deg");
		m.roll = ViewAxis.new("sim/current-view/goal-roll-offset-deg");
		ViewAxis.pilot_az = pilot_azN.getValue();

		m.heading.input = func { -15 * sin(me.roll) * cos(me.pitch) }
		m.pitch.input = func { -10 * sin(me.pitch) - me.pilot_az * 0.2 }
		m.roll.input = func { -20 * sin(me.roll) * cos(me.pitch) }

		m.reset();
		return m;
	},
	reset : func {
		me.heading.reset();
		me.pitch.reset();
		me.roll.reset();
	},
	apply : func {
		ViewAxis.pitch = pitchN.getValue();
		ViewAxis.roll = rollN.getValue();
		ViewAxis.pilot_az = 0.1 * pilot_azN.getValue() + ViewAxis.pilot_az * 0.9;

		me.heading.apply();
		me.pitch.apply();
		me.roll.apply();
	},
	add_offsets : func {
		me.heading.add_offset();
		me.pitch.add_offset();
		me.roll.add_offset();
	},
};


var original_resetView = view.resetView;
view.resetView = func {
	original_resetView();
	if (cockpit_view and managed_view) {
		view_manager.add_offsets();
	}
}


main_loop = func {
	if (cockpit_view and managed_view) {
		view_manager.apply();
	}
	settimer(main_loop, 0);
}

var view_manager = nil;
view_manager = ViewManager.new();
main_loop();
# ================================= view management ===============================


# end 
