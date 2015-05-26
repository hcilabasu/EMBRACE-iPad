var canvas = document.getElementById('overlay');

var g = 0.1;
var radius = 20;
var amplitude = 100;
var speed;

var animatingObjects = new Array();
var animatingObjectsIndex = -1;

var requestId;

function AnimationObject(object, posX, posY, endX, endY, animName) {
    this.object = object;
    this.x = posX;
    this.y = posY;
    this.ex = endX;
    this.ey = endY;
    this.vx = 0;
    this.vy = 200;
    this.t0 = 0;
    this.dt;
    this.animName = animName;
    this.tempY = 0;
    this.ix = posX;
    this.iy = posY;
    this.maxSpeed = 3;
    this.maxForce = 0.2;
    this.ax = 0;
    this.ay = 0;
}

function animateObject(objectName, posX, posY, endX, endY, animName) {
    animName = String(animName);
    var animationObject = new AnimationObject(objectName, posX, posY, endX, endY, animName);
    
    animatingObjects.push(animationObject);
   
    animatingObjectsIndex++;

    animatingObjects[animatingObjectsIndex].tempY = animatingObjects[animatingObjectsIndex].y;
    animatingObjects[animatingObjectsIndex].t0 = new Date().getTime(); // initialize value of t0
    animFrame(animatingObjects[animatingObjectsIndex]);
    
}

function animFrame(object){
    requestId = requestAnimationFrame(function() { animFrame(object); }, canvas);
    if(object.animName == "bounceAnimation") {
        bounce(object);
    }
    else if(object.animName == "fallAnimation") {
        fall(object);
    }
    else if(object.animName == "bobAnimation") {
        bob(object);
    }
    else if(object.animName == "cheerAnimation") {
        cheer(object);
    }
    else if(object.animName == "floatAnimation") {
        float(object);
    }
}

function bounce(aniObject) {
    var t1 = new Date().getTime(); // current time in milliseconds since midnight on 1 Jan 1970
    aniObject.dt = 0.001*(t1-aniObject.t0); // time elapsed in seconds since last call
    aniObject.t0 = t1; // reset t0
    aniObject.y = aniObject.tempY + (Math.sin(aniObject.vy) * amplitude/2) + amplitude/2;
    aniObject.object.style.top = aniObject.y + "px";
    aniObject.vy += 0.02;
}

function bounce2(object, posX, posY2) {
    posY2 = tempY + (Math.sin(speed) * amplitude/2) + amplitude/2;
    object.style.top = posY + "px";
    speed += 0.02;
    
    aniObject.y = aniObject.tempY + (Math.sin(aniObject.vy) * amplitude/2) + amplitude/2;
    aniObject.object.style.top = aniObject.y + "px";
    aniObject.vy += 0.02;
}

function fall(aniObject) {
    var t1 = new Date().getTime(); // current time in milliseconds since midnight on 1 Jan 1970
    aniObject.dt = 0.001*(t1-aniObject.t0); // time elapsed in seconds since last call
    aniObject.t0 = t1; // reset t0
    
    if (aniObject.y >= aniObject.ey){
        aniObject.vy = 0;
        cancelAnimationFrame(requestId);
    }
    else {
        aniObject.vy += g;
        aniObject.y += aniObject.vy * aniObject.dt;
    }
    
    aniObject.object.style.top = aniObject.y + "px";
}

function bob(aniObject) {
    var t1 = new Date().getTime();
    aniObject.dt = 0.001*(t1-aniObject.t0);
    var seconds = Math.round(aniObject.dt % 60);

    if (seconds < 4) {
        var waveHeight = Math.sin(aniObject.tempY);
        waveHeight = waveHeight/4;
        aniObject.tempY += 0.1;
        aniObject.y += waveHeight;
        aniObject.object.style.top = aniObject.y + "px";
    }
    else {
        cancelAnimationFrame(requestId);
    }
}

function cheer(aniObject) {
    var t1 = new Date().getTime();
    aniObject.dt = 0.001*(t1-aniObject.t0);
    var seconds = Math.round(aniObject.dt % 60);

    if (seconds < 4) {
        var waveHeight = Math.sin(aniObject.tempY);
        aniObject.tempY += 0.1;
        aniObject.y += waveHeight;
        aniObject.object.style.top = aniObject.y + "px";
    }
    else {
        if(aniObject.y == aniObject.iy) {
           cancelAnimationFrame(requestId);
        }
    }
}

function float(aniObject) {
    //alert("Floating");

    aniObject.vx = Math.floor(Math.random() * (1 - (-1) + 1)) + (-1);
    //alert("Vx: " + aniObject.vx);
    aniObject.vy = Math.floor(Math.random() * (1 - (-1) + 1)) + (-1);
    //for (var i=0; i<animatingObjects.length; i++) {
        
        //separate(animatingObjects[i]);
        //velocity.add(acceleration);
        aniObject.vx += aniObject.ax;
        aniObject.vy += aniObject.ay;
        //velocity.limit(maxspeed);
        //Math.max(aniObject.vx, maxSpeed);
        //Math.max(aniObject.vy, maxSpeed);
        //location.add(velocity);
        aniObject.x += aniObject.vx;
        aniObject.object.style.left = aniObject.x + "px";
        aniObject.y += aniObject.vy;
        aniObject.object.style.top = aniObject.y + "px";
        //acceleration.mult(0);
        //aniObject.ax *= 0;
        //aniObject.ay *= 0;
        checkEdges(aniObject);
    //}
}


function separate (aniObject) {
    //alert("Separating");
    //= Math.floor(Math.random() * (maximum - minimum + 1)) + minimum;
    
    var desiredSeparation = (radius-8) * 2;
    var tempX;
    var tempY;
    var sumX;
    var sumY;
    var count = 0;
    
    for (var i=0; i<animatingObjects.length; i++) {
        //var dist = Math.sqrt( Math.pow((x1-x2), 2) + Math.pow((y1-y2), 2) );
        var dist = Math.sqrt( Math.pow((aniObject.x-animatingObjects[i].x), 2) + Math.pow((aniObject.y-animatingObjects[i].y), 2) );
        alert("Distance: " + dist);
        
        if ((dist > 0) && (dist < desiredSeparation)) {
            var diffX = aniObject.x - animatingObjects[i].x;
            var diffY = aniObject.y - animatingObjects[i].y;
            //sqrt((ax * ax) + (ay * ay) + (az * az))
            diffX = diffX / Math.sqrt(Math.pow(diffX, 2) + Math.pow(diffY, 2));
            diffY = diffY / Math.sqrt(Math.pow(diffX, 2) + Math.pow(diffY, 2));
            diffX = diffX / dist;
            diffY = diffY / dist;
            sumX += diffX;
            sumY += diffY;
            count++;
        }
    }
    
    if (count > 0) {
        sumX = sumX / Math.sqrt(Math.pow(sumX, 2) + Math.pow(sumY, 2));
        sumY = sumY / Math.sqrt(Math.pow(sumX, 2) + Math.pow(sumY, 2));
        sumX *= aniObject.maxSpeed;
        sumY *= aniObject.maxSpeed;
        //Math.max(value, maxValue)
        var steerX = sumX - aniObject.vx;
        var steerY = sumY - aniObject.vy;
        Math.max(steerX, aniObject.maxForce);
        Math.max(steerY, aniObject.maxForce);
        aniObject.ax += steerX;
        aniObject.ay += steerY;
    }
}

function checkEdges(aniObject) {
    if (aniObject.x < 0 || aniObject.x > canvas.width - 75) {
        aniObject.vx = -aniObject.vx;
    }
    if (aniObject.y < 0 || aniObject.y > canvas.height - 75) {
        aniObject.vy = -aniObject.vy;
    }
}

// Debug
// Use console.log(message); message is of type string
console = new Object();

console.log = function(log) {
    var iframe = document.createElement("IFRAME");
    iframe.setAttribute("src", "ios-log:#iOS#" + log);
    document.documentElement.appendChild(iframe);
    iframe.parentNode.removeChild(iframe);
    iframe = null;
};

console.debug = console.log;
console.info = console.log;
console.warn = console.log;
console.error = console.log;