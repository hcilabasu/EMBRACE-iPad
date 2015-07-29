var groupings = new Array(); //Stores objects that may be grouped together. This array will now be a 1D array of objects that contains Connection objects. These Connection objects will contain the necessary information for each grouping. All functions that rely on this specific data structure will need to be updated.

var STEP = 5; //Step size used for animation when grouping and ungrouping.

/*
 * Moves the specified object to the new X,Y coordinated and takes care of all visual feedback.
 */
function moveObject(object, newX, newY, updateCon) {
    //Call the move function
    move(object, newX, newY, updateCon);
    
    //Highlight the object that is being moved. If it's part of a group of objects, highlight the entire group.
    //Note: It may be worth moving the group highlighting code into its own function and calling it from the PMView controller. If this is done, there's no need for a moveObject and a move function anymore, so these should be combined again.
    //Get objects this object may be grouped with.
    var groupedWithObjects = new Array();
    groupedWithObjects[0] = object;
    
    getObjectsGroupedWithObject(object, groupedWithObjects);
    
    //Pass the array into the the getboundingbox function to determine the size and location of the bounding box for the entire group so the entire group is highlighted together.
    var box = getBoundingBoxOfGroup(groupedWithObjects);
    
    //highlight the group (or the single object if there's just one).
    highlight(box.x, box.y, box.width, box.height);
}

/* 
 * Function that does the actual moving of the object specified to the new x,y coordinates
 * Also checks to see if this particular object is grouped to other objects.
 * If it is, all other objects it's grouped to are also moved.
 * This includes objects that are grouped to objects that it is grouped to.
 */
function move(object, newX, newY, updateCon) {
    if(object == null)
        alert("object is null");
    
    //Clear hotspots and highlights in case the user put down the object and these no longer need to be shown.
    clearAllHighlighted();
    clearAllHotspots();

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
    
    //Update the Connection information if we are not updating it manually
    if(!updateCon) {
        updateConnection(object, deltaX, deltaY);
    }
}

/*
 * Function that updates the hotspot locations in the Connection containing the specified
 * object. This is called manually after an object stops moving. Otherwise, the Connection
 * information is updated while the object is moving in the move function.
 */
function updateConnection(object, deltaX, deltaY) {
    //Get objects this object may be grouped with.
    var groupedWithObjects = new Array();
    groupedWithObjects[0] = object; //If we don't do this the original object will be added in the recursive method.
    
    getObjectsGroupedWithObject(object, groupedWithObjects);
    
    //Make sure we also update the Connection information for all objects that just got moved.
    //This is necessary for the objectGroupedAtHotspot function.
    //TODO: This still doesn't seem like it's working completely, because I can have the farmer pick up the hay, and then put the farmer and hay in the cart, and the hay will be connected to the cart at the same location that the hay is connected to the farmer....why isn't this updating all the time? Not only that, but it crashes the systems. Either this isn't working, or the menu is showing possibilities for disconnecting items that aren't actually connected.
    for(var i = 0; i < groupedWithObjects.length; i ++) {
        for(var j = 0; j < groupings.length; j ++) {
            var group = groupings[j];
            
            //We only have to check the object we're currently looking for right now.
            //All other object hotspots will be updated accordingly later as we go through the outer loop.
            if(groupedWithObjects[i].id == group.obj1.id) {
                group.obj1x = group.obj1x + deltaX;
                group.obj1y = group.obj1y + deltaY;
            }
            else if(groupedWithObjects[i].id == group.obj2.id) {
                group.obj2x = group.obj2x + deltaX;
                group.obj2y = group.obj2y + deltaY;
            }
        }
    }
}

/*
 * Returns the top left corner and width and height of the group of objects specified in a BoundingBox object.
 * This function does not check whether or not the group of objects passed in is actually connected.
 * so the function can be used for any set of objects. 
 * Instead, it just finds the left-most, top-most, right-most and bottom-most points to calculate the
 * necessary information.
 * The group parameter contains an array of the elements that are grouped together, as specified by
 * the getObjectsGroupedWithObject function, for example.
 */
function getBoundingBoxOfGroup(group) {
    //Just in case, make sure we're provided with at least one object.
    if(group.length > 0) {
        //set all of our locations to the first object for now.
        var leftMostPoint = group[0].offsetLeft;
        var topMostPoint = group[0].offsetTop;
        var rightMostPoint = group[0].offsetLeft + group[0].offsetWidth;
        var bottomMostPoint = group[0].offsetTop + group[0].offsetHeight;
    
        //If there is more than 1 item, go through the rest of the array.
        for(var i = 1; i < group.length; i ++) {
            if(group[i].offsetLeft < leftMostPoint)
                leftMostPoint = group[i].offsetLeft;
            if(group[i].offsetTop < topMostPoint)
                topMostPoint = group[i].offsetTop;
            if(group[i].offsetLeft + group[i].offsetWidth > rightMostPoint)
                rightMostPoint = group[i].offsetLeft + group[i].offsetWidth;
            if(group[i].offsetTop + group[i].offsetHeight > bottomMostPoint)
                bottomMostPoint = group[i].offsetTop + group[i].offsetHeight;
        }
        
        //Create the bounding box.
        var box = new BoundingBox(leftMostPoint, topMostPoint, rightMostPoint - leftMostPoint,
                                      bottomMostPoint - topMostPoint);
    
        return box;
    }
    
    return null;
}

/*
 * Bounding box object used to return the necessary information for the space requirements of a set of objects.
 */
function BoundingBox(topX, topY, totalWidth, totalHeight) {
    this.x = topX;
    this.y = topY;
    this.width = totalWidth;
    this.height = totalHeight;
}

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
 * Group the two objects at the specified hotspots.
 * x1,y1 specifies the hotspot location of object1 that will be grouped with the hotspot of object2 specified by x2,y2.
 * Object1 is the object that is being manipulated. Object 2 is static when the grouping is animated.
 * TODO:  Change the size and z-index of the objects so that they fit together properly.
 */
function groupObjectsAtLoc(object1, x1, y1, object2, x2, y2) {
    var group = new Connection(object1, x1, y1, object2, x2, y2);
    
    //Animate the grouping before adding them to the grouped objects array so that they animate correctly.
    animateGrouping(group);
    
    //Add them to the grouped objects array.
    groupings[groupings.length] = group;

    clearAllHighlighted();
}

/* 
 * This function takes a new group that has been created and animates it appropriately so that the object that was being moved
 * slowly animated towards the other object. the x and y coordinates of the connection specify the two hotspots that are joined.
 * object1 is the one that will be moving toward object 2. 
 * We need to calculate the delta movement and then apply it to the top, left corner of object 1 over time.
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
        //Why is it that if these two lines of code get commented out with the added nested for loop in the move function
        //the code freezes?
        group.obj1x = group.obj1x + changeX;
        group.obj1y = group.obj1y + changeY;
        
        //Move the object using the move function so that all other objects it's already connected to are moved with it.
        move(group.obj1, group.obj1.offsetLeft + changeX, group.obj1.offsetTop + changeY, false);
        
        //Call the function again after a 200 ms delay. TODO: Figure out why the delay isn't working.
        setTimeout(animateGrouping(group), 5000);
    }
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
    
    clearAllHighlighted();
}

/*
 * Animate the ungrouping by moving the objects away from each other.
 * Do so by ensuring that the objects no longer overlap and by putting a 10 pixel space in between them.
 * Keep in mind that objects should not be moved off screen when doing so.
 * TODO: Move objects towards the edges of the screens to avoid overlap with other objects toward the middle of the scene.
 * TODO: Once we figure out why the timeout doesn't work in the grouping animation,
 *       add in a timeout here too to smooth the animation.
 * TODO: It would be ideal to give priority to objects that can move on their own. E.g. the chicken is standing on the hay.
 *       Ungrouping the chicken and hay would result in only the chicken moving, not the hay as well.
 */
function animateUngrouping(group) {
    var GAP = 10; //we want a 10 pixel gap between objects to show that they're no longer grouped together.
    //Figure out which is the left most and which is the right most object. The left most object will move left and the right most object will move right. TODO: What implications does this have for the rest of the scene? For example, when the left most object is also one connected to an object to its right. Do we want to put in additional rules to deal with this, or are we going to calculate the "left-most" and "right-most" objects as whatever groups of objects we'll need to move. Should we instead move the smaller of the two objects away from the larger of the two. What about generalizability? What happens when we've got 2 groups of objects that need to ungroup, or alternately what if the object is connected to multiple things at once, how do we move it away from the object that it was just ungrouped from, while keeping it connected to the objects it's still grouped with. Do we animate both sets of objects or just one set of objects?
    
    //Lets start with the simplest case and go from there. 2 objects are grouped together and we just want to move them apart.
    //There are 2 possibilities. Either they are partially overlapping (or connected on the edges), or one object is contained within the other.
    //Figure out which one is the correct one. Then figure out which direction to move them and which object we're moving if we're not moving both.
    //If object 1 is contained within object 2.
    if(objectContainedInObject(group.obj1, group.obj2)) {
        //alert("check 1" + group.obj1.id + " contained in " + group.obj2.id);
        //For now just move the object that's contained within the other object toward the left until it's no longer overlapping.
        //Also make sure you're not moving it off screen.
        while((group.obj1.offsetLeft + group.obj1.offsetWidth + GAP > group.obj2.offsetLeft) &&
              (group.obj1.offsetLeft - STEP > 0)) {
            move(group.obj1, group.obj1.offsetLeft - STEP, group.obj1.offsetTop, false);
        }
    }
    //If object 2 is contained within object 1.
    else if(objectContainedInObject(group.obj2, group.obj1)) {
        //alert("check 2" + group.obj2.id + " contained in " + group.obj1.id);
        //For now just move the object that's contained within the other object toward the left until it's no longer overlapping.
        //Also make sure you're not moving it off screen.
        
        while((group.obj2.offsetLeft + group.obj2.offsetWidth + GAP > group.obj1.offsetLeft) &&
              (group.obj2.offsetLeft - STEP > 0)) {
            move(group.obj2, group.obj2.offsetLeft - STEP, group.obj2.offsetTop, false);
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
                    move(group.obj1, group.obj1.offsetLeft - STEP, group.obj1.offsetTop, false);
                
                if(group.obj2.offsetLeft + group.obj2.offsetWidth + STEP < window.innerWidth)
                    move(group.obj2, group.obj2.offsetLeft + STEP, group.obj1.offsetTop, false);
            }
        }
        else {
            //Move obj2 left by STEP and obj1 right by STEP until there's a distance of 10 pixels between them.
            //Change the location of the object.
            while(group.obj2.offsetLeft + group.obj2.offsetWidth + GAP > group.obj1.offsetLeft) {
                if(group.obj1.offsetLeft + group.obj1.offsetWidth + STEP < window.innerWidth)
                    move(group.obj1, group.obj1.offsetLeft + STEP, group.obj1.offsetTop, false);
                
                if(group.obj2.offsetLeft - STEP > 0)
                    move(group.obj2, group.obj2.offsetLeft - STEP, group.obj2.offsetTop, false);
            }
        }
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
function getObjectsGroupedWithObject(object, groupedObjects) {
    //Go through the entire list of connections.
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
 * The objectList is a list of individual objects.
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
 * The object list is a list of Connections.
 */
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
 * Returns null if no object grouped, or the object id otherwise.
 * It's possible that there's some variability here, so we're going to provide a 2 pixel margin.
 * This variability exists because the calculation of the function that figures out where the hotspot location is in the objC 
 * does not quite match where the JS thinks it is based on the Connection. 
 */
function objectGroupedAtHotspot(object, x, y) {
    var MARGIN = 13;
    //alert(object + " " + x + " " + y);
    for(var i = 0; i < groupings.length; i ++) {
        var group = groupings[i];
        
        if(object.id == group.obj1.id) {
            //alert("inside if");
            var diffX = Math.abs(x - group.obj2x);
            var diffY = Math.abs(y - group.obj2y);
            //alert(diffX + " " + diffY);
            if(diffX < MARGIN && diffY < MARGIN) {
                return group.obj2.id;
            }
        }
        else if(object.id == group.obj2.id) {
            //alert("inside else");
            var diffX = Math.abs(x - group.obj1x);
            var diffY = Math.abs(y - group.obj1y);
            //alert(diffX + " " + diffY);
            if(diffX < MARGIN && diffY < MARGIN) {
                return group.obj1.id;
            }
        }
    }
    
    return null;
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
 * Swaps the current image src used by objectId for the alternateSrc and adjusts the image width and location
 */
function swapImageSrc(objectId, alternateSrc, width, left, top) {
    var image = document.getElementById(objectId); //get the image
    
    image.src = "../Images/" + alternateSrc; //swap image
    
    //Adjust image width and location
    image.style.width = width;
    image.style.left = left + "%";
    image.style.top = top + "%";
}

/*
 Loads an image at a given location
 */
function loadImage(objectId, source, width, left, top, className, zPosition) {
    var image = document.createElement("img");
    
    image.src = "../Images/" + source; //load image
    
    //Adjust image style    
    image.style.width = width;
    image.style.left = left + "%";
    image.style.top = top + "%";
    image.style.zIndex = zPosition;
    
    image.alt = objectId;
    image.className = className;
    image.id = objectId;
    
    var images = document.getElementById('images');
    images.appendChild(image);
}

/*
 Removes an image as specified on the metadata
 */

function removeImage(objectId) {
    var image = document.getElementById(objectId);
    image.parentNode.removeChild(image);
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

/*
 * Highlights only the specified object.
 * This function is called by the PMView controller to highlight overlapping objects that have relevant relationships
 * with object being moved. The parameter 'under' indicates that the highlighting should be performed
 * under the object
 */
function highlightObject(object) {
    highlight(object.offsetLeft, object.offsetTop, object.offsetWidth, object.offsetHeight, "under");
}

/* 
 * Create an oval highlight using the top left corner and width and height specified.
 * If highlighting only one object the top left corner specified will be based on the offsetLeft and offsetTop properies
 * and the width and height will be based on the offsetWidth and offsetTop.
 * If highlighting a group of objects, the top left corner will specify the top left corner of the entire group, and the 
 * width and height will be the width and height of the entire group of objects.
 * TODO: Refine this so it looks a bit better. It seems to be slightly offset sometimes.
 */
function highlight(topleftX, topleftY, objectWidth, objectHeight, highlightType) {
    var canvas = document.getElementById('highlight');
    
    //Make sure the canvas is the size of the window. If not, make it the same size.
    //NOTE: This doesn't work, but we need something like this.
    /*
     if(canvas.width != window.innerWidth)
     canvas.width = window.innerWidth;
     if(canvas.height != window.innerHeight)
     canvas.height = window.innerheight;
     */
    
    var context = canvas.getContext('2d');
    
    //Get the size of the image and add 50 px to make the oval larger than the image.
    var width = objectWidth + 50;
    var height = objectHeight + 50;
    
    //Get the top-left corner and subtract 25 px to make the oval larger than the image.
    var x = topleftX - 25;
    var y = topleftY - 25;

    //Figure out where our bezier points need to be.
    var kappa = .5522848;
    var ox = (width / 2) * kappa; // control point offset horizontal
    var oy = (height / 2) * kappa; // control point offset vertical
    var xe = x + width;           // x-end
    var ye = y + height;          // y-end
    var xm = x + width / 2;       // x-middle
    var ym = y + height / 2;       // y-middle
    
    //Draw the oval.
    context.beginPath();
    //Create a halo effect.
    context.strokeStyle = "rgba(250, 250, 210, .2)";
    context.lineWidth = 5;
    context.moveTo(x, ym);
    context.bezierCurveTo(x, ym - oy, xm - ox, y, xm, y);
    context.bezierCurveTo(xm + ox, y, xe, ym - oy, xe, ym);
    context.bezierCurveTo(xe, ym + oy, xm + ox, ye, xm, ye);
    context.bezierCurveTo(xm - ox, ye, x, ym + oy, x, ym);
    context.closePath();
    context.stroke();
    context.fillStyle = "rgba(255, 250, 205, .4)";
    context.fill();
    
    // If objects are being higlighted (over mode) move the canvas to 100 on the z-index
    // Otherwise (under mode) keep the canvas position at 0
    if (highlightType == "over") {
        document.getElementById('highlight').style.zIndex = "100";
    }
    else if (highlightType == "under") {
        document.getElementById('highlight').style.zIndex = "0";
    }
}

/*
 * Remove highlights from all objects.
 */
function clearAllHighlighted() {
    var canvas = document.getElementById('highlight');
    var context = canvas.getContext('2d');
    
    context.clearRect(0, 0, canvas.width, canvas.height);
    // Move the highlight canvas its original z-position (0)
    document.getElementById('highlight').style.zIndex = "0";
}

/* 
 * Draw hotspot at location x,y with the specified color.
 */
function drawHotspot(x, y, color) {
    var canvas = document.getElementById('overlay');
    
    //Make sure the canvas is the size of the window. If not, make it the same size.
    //NOTE: This doesn't work, but we need something like this if we ever end up working in different sized screens.
    /*
     if(canvas.width != window.innerWidth)
        canvas.width = window.innerWidth;
    if(canvas.height != window.innerHeight)
        canvas.height = window.innerheight;
     */
    
    var context = canvas.getContext('2d');
    var radius = 10;

    context.beginPath();
    context.arc(x, y, radius, 0, 2 * Math.PI, false);
    context.fillStyle = color;
    context.fill();
    
    //Move the overlay canvas to 100 in order to display the hotspots on top of the objects
    document.getElementById('overlay').style.zIndex = "100";
}

/*
 * Clear all hotspots.
 */
function clearAllHotspots() {
    var canvas = document.getElementById('overlay');
    var context = canvas.getContext('2d');

    context.clearRect(0, 0, canvas.width, canvas.height);
    
    //Move the overlay canvas to its original z-index postion (0)
    document.getElementById('overlay').style.zIndex = "0";
}

function getSentenceText(sentenceId){
    
    return sentenceId.innerHTML;
}

function getSentenceClass(sentenceId){
    
    return sentenceId.className;
}

function toggleSentenceUnderline(sentenceId) {
    if (sentenceId.style.textDecoration == "underline") {
        sentenceId.style.textDecoration = "none";
    }
    else if (sentenceId.style.textDecoration == "none") {
        sentenceId.style.textDecoration = "underline";
    }
}

function getSentenceColor(sentenceId) {
    return sentenceId.style.color;
}

/*
 * Highlights the specified object on word tap.
 * This function is called by the PMView controller to highlight objects when their word has been clicked on.
 * The parameter 'over' indicates that the highlighting should be performed
 * over the object
 */
function highlightObjectOnWordTap(object) {
    highlight(object.offsetLeft, object.offsetTop, object.offsetWidth, object.offsetHeight, "over");
}

/*
 * Highlights the specified area on word tap.
 * This function is called by the PMView controller to highlight areas when their word has been clicked on.
 * The parameter 'over' indicates that the highlighting should be performed
 * over the object
 */
function highlightArea2() {
    console.log("CALLING HIGHLIGHT");
    var smooth_value = .5522848;
    
    var canvas = document.getElementById('highlight');
    var context = canvas.getContext('2d');
    
    context.beginPath();
    context.strokeStyle = "rgba(250, 250, 210, .2)";
    context.lineWidth = 5;
    //context.moveTo(path[0][0], path[0][1]);
    context.moveTo(path[1][0], path[1][1]);
    
    //var i = 2;
    for (var i = 3; i < pathIndex; i++) {
        
        // Adapted from:
        // http://www.antigrain.com/research/bezier_interpolation/
        
        // Assume we need to calculate the control
        // points between (x1,y1) and (x2,y2).
        // Then x0,y0 - the previous vertex,
        //      x3,y3 - the next one.
        
        var x0 = path[i-3][0];
        var y0 = path[i-3][1];
        var x1 = path[i-2][0];
        var y1 = path[i-2][1];
        var x2 = path[i-1][0];
        var y2 = path[i-1][1];
        var x3 = path[i][0];
        var y3 = path[i][1];
    
        //console.log("X0: " + x0 + " Y0: " + y0 + " X1: " + x1 + " Y1: " + y1 + " X2: " + x2 + " Y2: " + y2 + " X3: " + x3 + " Y3: " + y3);
    
        var xc1 = (x0 + x1) / 2.0;
        var yc1 = (y0 + y1) / 2.0;
        var xc2 = (x1 + x2) / 2.0;
        var yc2 = (y1 + y2) / 2.0;
        var xc3 = (x2 + x3) / 2.0;
        var yc3 = (y2 + y3) / 2.0;
    
        //console.log("XC1: " + xc1 + " YC1: " + yc1 + " XC2: " + xc2 + " YC2: " + yc2 + " XC3: " + xc3 + " YC3: " + yc3);
    
        var len1 = Math.sqrt((x1-x0) * (x1-x0) + (y1-y0) * (y1-y0));
        var len2 = Math.sqrt((x2-x1) * (x2-x1) + (y2-y1) * (y2-y1));
        var len3 = Math.sqrt((x3-x2) * (x3-x2) + (y3-y2) * (y3-y2));
    
        //console.log("LEN1: " + len1 + " LEN2: " + len2 + " LEN3: " + len3);
    
        var k1 = len1 / (len1 + len2);
        var k2 = len2 / (len2 + len3);
        
        var xm1 = xc1 + (xc2 - xc1) * k1;
        var ym1 = yc1 + (yc2 - yc1) * k1;
        
        var xm2 = xc2 + (xc3 - xc2) * k2;
        var ym2 = yc2 + (yc3 - yc2) * k2;
        
        // Resulting control points. Here smooth_value is mentioned
        // above coefficient K whose value should be in range [0...1].
        var ctrl1_x = xm1 + (xc2 - xm1) * smooth_value + x1 - xm1;
        var ctrl1_y = ym1 + (yc2 - ym1) * smooth_value + y1 - ym1;
        
        var ctrl2_x = xm2 + (xc2 - xm2) * smooth_value + x2 - xm2;
        var ctrl2_y = ym2 + (yc2 - ym2) * smooth_value + y2 - ym2;

        //console.log("1: " + ctrl1_x + " 2: " + ctrl1_y + " 3: " + ctrl2_x + " 4: " + ctrl2_y);
        context.bezierCurveTo(ctrl1_x, ctrl1_y, ctrl2_x, ctrl2_y, path[i-1][0], path[i-1][1]);
    
    }
    context.closePath();
    context.stroke();
    context.fillStyle = "rgba(255, 250, 205, .4)";
    context.fill();
    
    document.getElementById('highlight').style.zIndex = "100";
}

function highlightArea() {
    //console.log("CALLING HIGHLIGHT");
    var canvas = document.getElementById('highlight');
    var context = canvas.getContext('2d');
    
    context.beginPath();
    context.strokeStyle = "rgba(250, 250, 210, .2)";
    context.lineWidth = 5;
    context.moveTo(path[0][0], path[0][1]);
    for (var i = 1; i < pathIndex; i++) {
        context.lineTo(path[i][0], path[i][1]);
    }
    context.closePath();
    context.stroke();
    context.fillStyle = "rgba(255, 250, 205, .4)";
    context.fill();
    
    document.getElementById('highlight').style.zIndex = "100";
}

/*
 * Sets the text of a sentence
 */

function setInnerHTMLText (sentenceID, text) {
    document.getElementById(sentenceID).innerHTML = text;    
}

function setOuterHTMLText (sentenceID, text) {
    document.getElementById(sentenceID).outerHTML = text;
}

function getImagePosition (object) {
    var position = new Array();
    position[0] = object.offsetLeft;
    position[1] = object.offsetTop;
    
    if(position.length > 0) {
        var overlapString = "";
        overlapString = overlapString + position[0].toString() + ", " ;
        overlapString = overlapString + position[1].toString();
        return overlapString;
    }
    else
        return null;
}