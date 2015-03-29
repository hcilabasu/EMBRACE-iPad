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
    if(object.animName == "fallAnimation") {
        fall(object);
    }
    if(object.animName == "bobAnimation") {
        bob(object);
    }
    if(object.animName == "cheerAnimation") {
        cheer(object);
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
        aniObject.vy += g
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