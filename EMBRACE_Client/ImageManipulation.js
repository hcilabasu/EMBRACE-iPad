var groupings = new Array(); //Stores objects that may be grouped together. This array will now be a 1D array of objects that contains Connection objects. These Connection objects will contain the necessary information for each grouping. All functions that rely on this specific data structure will need to be updated.

var overlayGraphics = new jsGraphics(document.getElementById('overlay')); //Create jsGraphics object

var STEP = 5; //Step size used for animation when grouping and ungrouping.
/*
 * Moves the specified object to the new X,Y coordinated.
 * Also checks to see if this particular object is grouped to other objects.
 * If it is, all other objects it's grouped to are also moved.
 * This includes objects that are grouped to objects that it is grouped to. (recursive)
 */
function moveObject(object, newX, newY) {
    if(object == null)
        alert("object is null");

    //Calculate a delta change, so we know what to move grouped objects by.
    var deltaX = newX - object.offsetLeft;
    var deltaY = newY - object.offsetTop;
    
    //Move the object to the new location.
    object.style.left = newX + "px";
    object.style.top = newY + "px";
    
    //Get objects this object may be grouped with.
    var groupedWithObjects = new Array();
    groupedWithObjects[0] = object; //If we don't do this the original object will be added in the recursive method.
    
    getObjectsGroupedWithObject(object, groupedWithObjects);
    
    //If it's grouped with other objects, move those as well.
    //Skip the object at location 1, because that's our original object that we've already moved.
    for(var i = 1; i < groupedWithObjects.length; i ++) {
        groupedWithObjects[i].style.left = groupedWithObjects[i].offsetLeft + deltaX + "px";
        groupedWithObjects[i].style.top =  groupedWithObjects[i].offsetTop + deltaY + "px";
    }
    
    //Check to see if any of the objects in this group are overlapping with any other objects that they are not grouped with.
    //If so, go ahead and highlight those objects.
    //Also make sure to remove highlighting of objects that should no longer be highlighted.
    //clearAllHighlighted();
    clearCanvas(); 
    
    /*for(var i = 0; i < groupedWithObjects.length; i ++) {
        var overlapArray = checkObjectOverlap(groupedWithObjects[i]);
    
        for(i = 0; i < overlapArray.length; i ++) {
            highlight(overlapArray[i][1]);
        }
    }*/

    //if(groupings.length > 0)
    //    alert("object: " + object.id);
}

/* 
 * Function finds whether two objects are overlapping. 
 * If they are, then it adds them as a group to the groupings array.
 */
/*function checkObjectOverlap(object) {
    //Check to see if object with object is overlapping any other object that it can be grouped with.
    var manipulationObjects = document.getElementsByClassName('manipulationObject');

    for(var i = 0; i < manipulationObjects.length; i++) { //go through all manipulationObjects, checking for overlap.
        if(object.id != manipulationObjects[i].id) { //Don't check the object you're moving against itself.
            //check to see if objects overlap. If they do, add the object to the array.
            if((object.offsetLeft + object.offsetWidth > manipulationObjects[i].offsetLeft) && (object.offsetLeft < manipulationObjects[i].offsetLeft + manipulationObjects[i].offsetWidth) && (object.offsetTop + object.offsetHeight > manipulationObjects[i].offsetTop) && (object.offsetTop < manipulationObjects[i].offsetTop + manipulationObjects[i].offsetHeight)) {

                //check to see if the 2 are already grouped together
                var areGrouped = areObjectsGrouped(object, manipulationObjects[i]);
                
                //if they're not grouped..group them.
                if(areGrouped == -1) {
                    var overlappedObjs = new Array();
                    overlappedObjs[0] = object;
                    overlappedObjs[1] = manipulationObjects[i];
                    groupings[groupings.length] = overlappedObjs;
                }
            }
        }
    }
}*/


/*
 * Function finds whether objects overlaps with any other manipulation object.
 */
function checkObjectOverlap(object) {
    //Check to see if object with object is overlapping any other object that it can be grouped with.
    var manipulationObjects = document.getElementsByClassName('manipulationObject');
    var overlapArray = new Array();
    
    for(var i = 0; i < manipulationObjects.length; i++) { //go through all manipulationObjects, checking for overlap.
        if(object.id != manipulationObjects[i].id) { //Don't check the object you're moving against itself.
            //check to see if objects overlap. If they do, add the object to the array.
            if((object.offsetLeft + object.offsetWidth > manipulationObjects[i].offsetLeft) && (object.offsetLeft < manipulationObjects[i].offsetLeft + manipulationObjects[i].offsetWidth) && (object.offsetTop + object.offsetHeight > manipulationObjects[i].offsetTop) && (object.offsetTop < manipulationObjects[i].offsetTop + manipulationObjects[i].offsetHeight)) {
                
                //check to see if the 2 are already grouped together
                var areGrouped = areObjectsGrouped(object, manipulationObjects[i]);
                
                //This check may need to be moved over to the checkObjectOverlap function.
                //if they're not grouped, group them.
                if(areGrouped == -1) {
                    var overlappedObjs = new Array();
                    overlappedObjs[0] = object;
                    overlappedObjs[1] = manipulationObjects[i];
                    overlapArray[overlapArray.length] = overlappedObjs;
                }
            }
        }
    }
    
    return overlapArray;
}

/* 
 * Function calls checkObjectOverlap to get the array of overlapping objects. 
 * It then takes this array and concatinates it into a string that can be used by the 
 * objectiveC code. 
 */
function checkObjectOverlapString(object) {
    var overlapArray = checkObjectOverlap(object);
    
    if(overlapArray.length > 0) {
        var overlapString = "";
        
        for(var i = 0; i < overlapArray.length - 1; i ++) {
            //overlapString = overlapString + overlapArray[i][0].id + ", " + overlapArray[i][1].id + "; ";
            overlapString = overlapString + overlapArray[i][1].id + ", " ;
        }
        
        //overlapString = overlapString + overlapArray[overlapArray.length - 1][0].id + ", " + overlapArray[overlapArray.length - 1][1].id;
        overlapString = overlapString + overlapArray[overlapArray.length - 1][1].id;
        
        return overlapString;
    }
    else
        return null;
}

/*
 * Function calls checkObjectOverlap to see if this object is overlapping
 * with any other objects. 
 * If it is, then it adds the overlapping objects to the groupings array.
 */
function groupOverlappingObjects(object) {
    var overlapArray = checkObjectOverlap(object);
    
    //Go through the array returned by the checkObjectOverlap function to see if the objects are already grouped. If they aren't, group them.
    for(i = 0; i < overlapArray.length; i ++) {
        groupings[groupings.length] = overlapArray[i];
    }
    
    //Clear all the highlighting because we've finished our grouping.
    //clearAllHighlighted();
}

/*
 * If we want to do this correctly, we'll need to use another function to change the size of the object that fits within
 * the other object. Additionally, we'll have to change the location of the objects when they interact to show that they're
 * interacting.
 * The function takes in two object id parameters. object1 is the object that is being manipulated. Object 2 is the static
 * object that object1 is being grouped with. (x2, y2) correspond to the coordinates of the hotspot for object 2 that
 * the coordinates (x1, y1) of object1 should move toward and snap to.
 */
//Originally this was designed such that we only maintained information about which 2 objects were connected to each other. We want to change our format for our list of connections such that we contain information about the individual hotspots at which 2 objects are connected. Additionally, we want to make sure that if there's already an object connected at a particular hotspot, we cannot connect another object at that same hotspot. This will help in the following ways: 1) it will provide the necessary location information to animate the grouping and ungrouping of objects. 2) it will keep multiple objects from being grouped at the same location, making it easir to detect whether or not transferance between two objects needs to occur.
/*function groupObjectsAtLoc(object1, x1, y1, object2, x2, y2) {
    var group = new Array();
    group[0] = object1;
    group[1] = object2;

    groupings[groupings.length] = group;
}*/

function groupObjectsAtLoc(object1, x1, y1, object2, x2, y2) {
    var group = new Connection(object1, x1, y1, object2, x2, y2);
    //alert("grouping " + object1.id + " and " + object2.id);
    groupings[groupings.length] = group;

    animateGrouping(group);
}

/* 
 * This function takes a new group that has been created and animates it appropriately so that the object that was being moved
 * slowly animated towards the other object. the x and y coordinates of the connection specify the two hotspots that are joined.
 * object1 is the one that will be moving toward object 2. 
 * We need to calculate the delta movement and then apply it to the top, left corner of object 1 over time.
 * TODO: Come back to this for instances in which objects that being animated are also connected to other objects that should be moved with them.
 */
function animateGrouping(group) {
    //Calculate the total change that needs to occur, even though we'll only move a small step size towards the hotspot every time.
    var deltaX = group.obj2x - group.obj1x;
    var deltaY = group.obj2y - group.obj1y;
    
    //Check to see whether there is more animation to be done (assume that deltaX and deltaY will both be 0 if no more animation needs to occur.
    if((deltaX != 0) || (deltaY != 0)) {
        //used for the specific change that occurs on this animation turn.
        var changeX = 0;
        var changeY = 0;
        
        //Check to see if delta change is greater than the step size (currently 5 pixels), and whether it's positive or negative.
        //Use this information to determine how much to move on this turn.
        if(deltaX < -STEP)
            changeX = -STEP;
        else if(deltaX < 0)
            changeX = deltaX;
        else if(deltaX > STEP)
            changeX = STEP;
        else if(deltaX > 0)
            changeX = deltaX;
        
        if(deltaY < -STEP)
            changeY = -STEP;
        else if(deltaY < 0)
            changeY = deltaY;
        else if(deltaY > STEP)
            changeY = STEP;
        else if(deltaY > 0)
            changeY = deltaY;
        
        //Update the x,y coordinates of the connection point for obj1 based on the new location.
        group.obj1x = group.obj1x + changeX;
        group.obj1y = group.obj1y + changeY;
        
        //Change the location of the object.
        group.obj1.style.left = group.obj1.offsetLeft + changeX + "px";
        group.obj1.style.top = group.obj1.offsetTop + changeY + "px";
        
        //Call the function again after a 200 ms delay. TODO: Figure out why the delay isn't working.
        setTimeout(animateGrouping(group), 5000);
    }
}

/*
 * A connection object specifying that a grouping exists between object1 and object2.
 * x1, y1 represents the hotspot location that belongs to object1. 
 * x2, y2 represents the hotspot location that belongs to object2.
 */
function Connection(object1, x1, y1, object2, x2, y2) {
    this.obj1 = object1;
    this.obj1x = x1;
    this.obj1y = y1;
    this.obj2 = object2;
    this.obj2x = x2;
    this.obj2y = y2
}

/*
 * Get the object ids that are grouped together to display to the user.
 * Return these object ids in a 2D array (of n x 2), where each row represents a link between two objects and is separated
 * by a semicolon. Each element in the row is separated by a comma.
 */
/*function getGroupedObjectsString(object) {
    //Get objects this object may be grouped with.
    var groupedWithObjects = new Array();
    
    getGroupedObjectsArray(object, groupedWithObjects);
    
    //alert("grouped with objects array length in getGroupedObjectsString: " + groupedWithObjects.length);
    
    if(groupedWithObjects.length > 0) {
        var objGroupString = groupedWithObjects[0][0].id + ", " + groupedWithObjects[0][1].id;
    
        for(var i = 1; i < groupedWithObjects.length; i ++) {
            objGroupString = objGroupString + "; " + groupedWithObjects[i][0].id + ", " + groupedWithObjects[i][1].id;
        }
    
        return objGroupString;
    }
    else
        return null;
}*/

function getGroupedObjectsString(object) {
    //Get objects this object may be grouped with.
    var groupedWithObjects = new Array();
    
    getGroupedObjectsArray(object, groupedWithObjects);
    
    if(groupedWithObjects.length > 0) {
        var group = groupedWithObjects[0];
        var objGroupString = group.obj1.id + ", " + group.obj2.id;
        
        for(var i = 1; i < groupedWithObjects.length; i ++) {
            group = groupedWithObjects[i];
            
            objGroupString = objGroupString + "; " + group.obj1.id + ", " + group.obj2.id;
        }
        
        return objGroupString;
    }
    else
        return null;
}

/*
 * Recursive function which finds all objects which are grouped together.
 * Need to recursively check objects due to the fact that 3 or more objects may be grouped at different times.
 * In this case groupedObjects will be an array of pairs of objects that are grouped together. 
 * TODO: come back to this and see if this and getObjectsGroupedWithObject can be combined.
 */
/*function getGroupedObjectsArray(object, groupedObjects) {
    //Go through the entire 2D array.
    for(var i = 0; i < groupings.length; i++) {
        if(object.id == groupings[i][0].id) {
            if(!pairInList(groupings[i][0], groupings[i][1], groupedObjects)) {
                //alert("found object: " + object.id + " and it's grouped with: " + groupings[i][1].id);
                
                groupedObjects[groupedObjects.length] = groupings[i];
                getGroupedObjectsArray(groupings[i][1], groupedObjects);
            }
        }
        else if(object.id == groupings[i][1].id) {
            if(!pairInList(groupings[i][0], groupings[i][1], groupedObjects)) {
                //alert("found object: " + object.id + " and it's grouped with: " + groupings[i][0].id);
                
                groupedObjects[groupedObjects.length] = groupings[i];
                getGroupedObjectsArray(groupings[i][0], groupedObjects);
            }
        }
    }
}*/

function getGroupedObjectsArray(object, groupedObjects) {
    //Go through the entire 2D array.
    for(var i = 0; i < groupings.length; i++) {
        var group = groupings[i];
        
        if(object.id == group.obj1.id) {
            if(!pairInList(group.obj1, group.obj2, groupedObjects)) {
                //alert(group.obj1.id + " and " + group.obj2.id + " are not in the connections list, adding them now");
                
                groupedObjects[groupedObjects.length] = group;
                getGroupedObjectsArray(group.obj2, groupedObjects);
            }
        }
        else if(object.id == group.obj2.id) {
            if(!pairInList(group.obj1, group.obj2, groupedObjects)) {
                //alert(group.obj1.id + " and " + group.obj2.id + " are not in the connections list, adding them now");
                
                groupedObjects[groupedObjects.length] = group;
                getGroupedObjectsArray(group.obj1, groupedObjects);
            }
        }
    }
}

/* 
 * Recursive function which finds all objects which are grouped together.
 * Need to recursively check objects due to the fact that 3 or more objects may be grouped at different times.
 * Return the list of objects that are all grouped together. 
 */
/*function getObjectsGroupedWithObject(object, groupedObjects) {
    //Go through the entire 2D array.
    for(var i = 0; i < groupings.length; i++) {
        if(object.id == groupings[i][0].id) {
            if(!objectInList(groupings[i][1], groupedObjects)) {
                groupedObjects[groupedObjects.length] = groupings[i][1];
                getObjectsGroupedWithObject(groupings[i][1], groupedObjects);
            }
        }
        else if(object.id == groupings[i][1].id) {
            if(!objectInList(groupings[i][0], groupedObjects)) {
                groupedObjects[groupedObjects.length] = groupings[i][0];
                getObjectsGroupedWithObject(groupings[i][0], groupedObjects);
            }
        }
    }
}*/

function getObjectsGroupedWithObject(object, groupedObjects) {
    //Go through the entire 2D array.
    for(var i = 0; i < groupings.length; i++) {
        var group = groupings[i];
        
        if(object.id == group.obj1.id) {
            if(!objectInList(group.obj2, groupedObjects)) {
                groupedObjects[groupedObjects.length] = group.obj2;
                getObjectsGroupedWithObject(group.obj2, groupedObjects);
            }
        }
        else if(object.id == group.obj2.id) {
            if(!objectInList(group.obj1, groupedObjects)) {
                groupedObjects[groupedObjects.length] = group.obj1;
                getObjectsGroupedWithObject(group.obj1, groupedObjects);
            }
        }
    }
}

/* 
 * Used as a helper method for getObjectsGroupedWithObject.
 * Checks to see if the objects is in the list so it isn't added again.
 */
function objectInList(object, objectList) {
    for(var i = 0; i < objectList.length; i ++)
        if(object.id == objectList[i].id)
            return true;
    
    return false;
}

/*
 * Used as a helper method for getGroupedObjectsArray.
 * Checks to see if the pair of objects are in the list so it isn't added again.
 * TODO: come back to this and see if this and objectInList can be combined.
 */
/*function pairInList(object1, object2, objectList) {
    for(var i = 0; i < objectList.length; i ++) {
        if((object1.id == objectList[i][0].id) && (object2.id == objectList[i][1].id)) {
            //alert("in if, object1 id: " + object1.id + " object2 id: " + object2.id);
            return true;
        }
        else if((object1.id == objectList[i][1]) && (object2.id == objectList[i][0].id)) {
            //alert("in else if, object1 id: " + object1.id + " object2 id: " + object2.id);
            return true;
        }
    }
    
    return false;    
}*/
function pairInList(object1, object2, objectList) {
    for(var i = 0; i < objectList.length; i ++) {
        var group = objectList[i];
        
        if((object1.id == group.obj1.id) && (object2.id == group.obj2.id)) {
            return true;
        }
        else if((object1.id == group.obj2.id) && (object2.id == group.obj1.id)) {
            return true;
        }
    }
 
    return false;
}

/*
 * Returns the index at which the objects are in the array if object1 and object 2 are grouped together, and -1 otherwise.
 */
/*function areObjectsGrouped(object1, object2) {
    for(var i = 0; i < groupings.length; i ++) {
        if((object1.id == groupings[i][0].id) && (object2.id == groupings[i][1].id))
            return i;
        else if((object2.id == groupings[i][0].id) && (object1.id == groupings[i][1].id))
            return i;
    }
    
    return -1;
}*/

function areObjectsGrouped(object1, object2) {
    for(var i = 0; i < groupings.length; i ++) {
        var group = groupings[i];
        
        if((object1.id == group.obj1.id) && (object2.id == group.obj2.id))
            return i;
        else if((object2.id == group.obj1.id) && (object1.id == group.obj2.id))
            return i;
    }
    
    return -1;
}

/* 
 * Checks to see if a particular hotspot for an object is already connected to another object.
 * This is necessary to ensure that we're not trying to connect two objects to the same hotspot. 
 * It's possible that at some point in time we want to allow multiple objects to connect to the same hotspot based on the object.
 * If so, a property should be added specifying the maximum number of connections that can be made to any one hotspot at a time.
 * For now, we assume this maximum is one for all objects. 
 * TODO: Need to make sure this still works if groupings are moved after created. Not sure that the hotspots are currently kept updated.
 */
function isObjectGroupedAtHotspot(object, x, y) {
    //alert("number of groupings: " + groupings.length);
    
    for(var i = 0; i < groupings.length; i ++) {
        var group = groupings[i];
        
        if(object.id == group.obj1.id) {
            //alert("found object " + object.id + " for hotspot location: (" + group.obj1x + ", " + group.obj1y + ") grouped with " + group.obj2.id + " and comparing to (" + x + ", " + y + ")");
            
            if((x == group.obj1x) && (y == group.obj1y)) {
                //alert("returning true");
                return true;
            }
        }
        else if(object.id == group.obj2.id) {
            //alert("found object " + object.id + " for hotspot location: (" + group.obj2x + ", " + group.obj2y +") grouped with " + group.obj1.id + " and comparing to (" + x + ", " + y + ")");
            
            if((x == group.obj2x) && (y == group.obj2y)) {
                //alert("returning true");
                return true;
            }
        }
    }
    
    return false;
}

/* 
 * Ungroups 2 objects from each other.
 */
function ungroupObjects(object1, object2) {
    //Get the index at which the objects are grouped.
    var areGrouped = areObjectsGrouped(object1, object2);
    
    //Make sure they are grouped, and if they are, ungroup them.
    if(areGrouped > -1) {
        //Grab the reference to the connection that needs to be removed so that animation can occur.
        var group = groupings[areGrouped];
        
        //Remove the connection.
        groupings.splice(areGrouped, 1);

        //Animate the ungrouping.
        animateUngrouping(group);
    }
}

/*
 * Animate the ungrouping by moving the objects away from each other. 
 * Do so by ensuring that the objects no longer overlap and by putting a 10 pixel space in between them.
 * Keep in mind that objects should not be moved off screen when doing so.
 * TODO: Need to handle more complex cases, such as when objects that are ungrouping are also still grouped to other objects.
 * TODO: Move objects towards the edges of the screens to avoid overlap with other objects toward the middle of the scene.
 * TODO: Once we figure out why the timeout doesn't work in the grouping animation, 
 *       add in a timeout here too to smooth the animation.
 * TODO: It would be ideal to give priority to objects that can move on their own. E.g. the chicken is standing on the hay.
 *       Ungrouping the chicken and hay would result in only the chicken moving, not the hay as well.
 */
function animateUngrouping(group) {
    var GAP = 10; //we want a 10 pixel gap between objects.
    //Figure out which is the left most and which is the right most object. The left most object will move left and the right most object will move right. TODO: What implications does this have for the rest of the scene? For example, when the left most object is also one connected to an object to its right. Do we want to put in additional rules to deal with this, or are we going to calculate the "left-most" and "right-most" objects as whatever groups of objects we'll need to move. Should we instead move the smaller of the two objects away from the larger of the two. What about generalizability? What happens when we've got 2 groups of objects that need to ungroup, or alternately what if the object is connected to multiple things at once, how do we move it away from the object that it was just ungrouped from, while keeping it connected to the objects it's still grouped with. Do we animate both sets of objects or just one set of objects?
    
    //Lets start with the simplest case and go from there. 2 objects are grouped together and we just want to move them apart.
    //There are 2 possibilities. Either they are partially overlapping (or connected on the edges), or one object is contained within the other.
    //Figure out which one is the correct one. Then figure out which direction to move them and which object we're moving if we're not moving both.
    //If object 1 is contained within object 2.
    if(objectContainedInObject(group.obj1, group.obj2)) {
        //alert(group.obj1.id + " contained in " + group.obj2.id);
        //For now just move the object that's contained within the other object toward the left until it's no longer overlapping.
        //Also make sure you're not moving it off screen.
        while((group.obj1.offsetLeft + group.obj1.offsetWidth + GAP > group.obj2.offsetLeft) &&
              (group.obj1.offsetLeft - STEP > 0)) {
            group.obj1.style.left = group.obj1.offsetLeft - STEP + "px";
        }
    }
    //If object 2 is contained within object 1.
    else if(objectContainedInObject(group.obj2, group.obj1)) {
        //alert(group.obj2.id + " contained in " + group.obj1.id);
        //For now just move the object that's contained within the other object toward the left until it's no longer overlapping.
        //Also make sure you're not moving it off screen.
        while((group.obj2.offsetLeft + group.obj2.offsetWidth + GAP > group.obj1.offsetLeft) &&
             (grou.obj2.offsetLeft - STEP > 0)) {
            group.obj2.style.left = group.obj2.offsetLeft - STEP + "px";
        }
    }
    //Otherwise, partially overlapping or connected on the edges.
    else {
        //Figure out which is the leftmost object.
        if(group.obj1.offsetLeft < group.obj2.offsetLeft) {
            //Move obj1 left by STEP and obj2 right by STEP until there's a distance of 10 pixels between them.
            //Also make sure you're not moving either object offscreen.
            while(group.obj1.offsetLeft + group.obj1.offsetWidth + GAP > group.obj2.offsetLeft) {
                if(group.obj1.offsetLeft - STEP > 0)
                    group.obj1.style.left = group.obj1.offsetLeft - STEP + "px";
                
                if(group.obj2.offsetLeft + group.obj2.offsetWidth + STEP < window.innerWidth)
                    group.obj2.style.left = group.obj2.offsetLeft + STEP + "px";
            }
        }
        else {
            //Move obj2 left by STEP and obj1 right by STEP until there's a distance of 10 pixels between them.
            //Change the location of the object.
            while(group.obj2.offsetLeft + group.obj2.offsetWidth + GAP > group.obj1.offsetLeft) {
                if(group.obj1.offsetLeft + group.obj1.offsetWidth + STEP < window.innerWidth)
                    group.obj1.style.left = group.obj1.offsetLeft + STEP + "px";
                
                if(group.obj2.offsetLeft - STEP > 0)
                    group.obj2.style.left = group.obj2.offsetLeft - STEP + "px";
            }
        }
    }
}

/*
 * Helper method that tells us whether one object is completely contained within another object.
 * Will return true if object1 is contained in object2.
 */
function objectContainedInObject(object1, object2) {
   if((object1.offsetTop >= object2.offsetTop) &&
      (object1.offsetTop + object1.offsetHeight <= object2.offsetTop + object2.offsetHeight) &&
      (object1.offsetLeft > object2.offsetLeft) &&
      (object1.offsetLeft + object1.offsetWidth <= object2.offsetLeft + object2.offsetWidth))
       return true;
    else
        return false;
}

/*
 * This may be moved into a different js file, if there are more things to do when moving to the next sentence.
 * This function just sets the sentence opacity to the specified opacity.
 * It's used to setup the opacity when the activity loads, and when moving from one sentence to the next. 
 */
function setSentenceOpacity(sentenceId, opacity) {
    sentenceId.style.opacity = opacity;
}

function setSentenceColor(sentenceId, color) {
    sentenceId.style.color = color;
}

function setSentenceFontWeight(sentenceId, weight) {
    sentenceId.style.fontWeight = weight;
}

function highlight(object) {
    object.style.backgroundColor = "rgba(255, 250, 205, .4)";
    //object.style.border = "3px solid rgba(250, 250, 210, .2)";
    
    //When we highlight we also want to draw the hotspots for this object.
    //Not sure if we should call this from here or from the objectiveC code. 
    //drawHotspots(object);
}

function removeHighlight(object) {
    //object.style.border = "0px";
    object.style.backgroundColor = "transparent";
}

function clearAllHighlighted() {
    var manipulationObjects = document.getElementsByClassName('manipulationObject');

    for(var i = 0; i < manipulationObjects.length; i++)
        removeHighlight(manipulationObjects[i]);
}

/*function drawHotspot(x, y, color) {
    //Create jsColor object
    var col = new jsColor(color);
    
    //Create jsPoint object
    var pt1 = new jsPoint(x,y);
    
    //Draw filled circle with pt1 as center point and radius 30.
    overlayGraphics.fillCircle(col,pt1,10);
}*/

function drawHotspot(x, y, color) {
    var canvas = document.getElementById('overlay');
    
    //Instead of having to do this, figure out how to properly make it the right size in the epub or through css.
    //canvas.width = window.innerWidth;
    //canvas.height = window.innerHeight;
    
    //if(canvas == null)
    //    alert("canvas is null");
    //else
    //    alert("size of canvas: " + canvas.width + " x " + canvas.height);
    
    var context = canvas.getContext('2d');
    var radius = 10;

    context.beginPath();
    context.arc(x, y, radius, 0, 2 * Math.PI, false);
    context.fillStyle = color;
    context.fill();
}

/*function clearCanvas() {
    overlayGraphics.clear();
}*/

function clearCanvas() {
    var canvas = document.getElementById('overlay');
    //var canvas = document.getElementById('overlayCanvas');
    var context = canvas.getContext('2d');

    context.clearRect(0, 0, canvas.width, canvas.height);
}