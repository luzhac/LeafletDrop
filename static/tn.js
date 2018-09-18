
  var mapStyle = [{
    'stylers': [{'visibility': 'on'}]
  }, {
    'featureType': 'landscape',
    'elementType': 'geometry',
    'stylers': [{'visibility': 'on'}, {'color': '#fcfcfc'}]
  }, {
    'featureType': 'water',
    'elementType': 'geometry',
    'stylers': [{'visibility': 'on'}, {'color': '#bfd4ff'}]
  }];
  var map;
  var censusMin = Number.MAX_VALUE, censusMax = -Number.MAX_VALUE;
  var areaSelect={total:0,areas: new Set()}
  function initMap() {

    // load the map
    map = new google.maps.Map(document.getElementById('map'), {
      center: {lat: 51.1447013, lng: 0.3210841},
      zoom: 14,
      styles: mapStyle
    });


    // set up the style rules and events for google.maps.Data
    map.data.setStyle(styleFeature);
    map.data.addListener('mouseover', mouseInToRegion);
    map.data.addListener('mouseout', mouseOutOfRegion);
    map.data.addListener('click', mouseClick);

    // wire up the button
    var selectBox = document.getElementById('census-variable');
    google.maps.event.addDomListener(selectBox, 'change', function() {
      clearCensusData();
      loadCensusData(selectBox.options[selectBox.selectedIndex].value);
    });

    // state polygons only need to be loaded once, do them now
    loadMapShapes();

  }

  /** Loads the state boundary polygons from a GeoJSON source. */
  function loadMapShapes() {
    // load US state outline polygons from a GeoJson file
    map.data.loadGeoJson('http://:8081', { idPropertyName: 'postcode' });

    // wait for the request to complete by listening for the first feature to be
    // added
    google.maps.event.addListenerOnce(map.data, 'addfeature', function() {
      google.maps.event.trigger(document.getElementById('census-variable'),
          'change');
    });
  }

  /**
   * Loads the census data from a simulated API call to the US Census API.
   *
   * @param {string} variable
   */
  function loadCensusData(variable) {
    // load the requested variable from the census API (using local copies)
    // var xhr = new XMLHttpRequest();
    // variable='http://47.254.128.147:8080/static/pp'
    // xhr.open('GET', variable + '.json');
    // xhr.onload = function() {
    //   var censusData = JSON.parse(xhr.responseText);
    //   censusData.shift(); // the first row contains column names
    //   censusData.forEach(function(row) {
    //     var censusVariable = parseFloat(row[1]);
    //     var stateId = row[0];

    //     // keep track of min and max values
    //     if (censusVariable < censusMin) {
    //       censusMin = censusVariable;
    //     }
    //     if (censusVariable > censusMax) {
    //       censusMax = censusVariable;
    //       censusMax = 2500000;
    //     }

    //     // update the existing row with the new data


    //   });

      // update and display the legend
      censusMin=300000
      censusMax=2000000
      document.getElementById('census-min').textContent =
          censusMin.toLocaleString();
      document.getElementById('census-max').textContent =
          censusMax.toLocaleString();
    //};
  }

  /** Removes census data from each shape on the map and resets the UI. */
  function clearCensusData() {
    censusMin = Number.MAX_VALUE;
    censusMax = -Number.MAX_VALUE;
    map.data.forEach(function(row) {
      row.setProperty('average', undefined);
    });
    document.getElementById('data-box').style.display = 'none';
    document.getElementById('data-caret').style.display = 'none';
  }

  /**
   * Applies a gradient style based on the 'average' column.
   * This is the callback passed to data.setStyle() and is called for each row in
   * the data set.  Check out the docs for Data.StylingFunction.
   *
   * @param {google.maps.Data.Feature} feature
   */
  function styleFeature(feature) {
    var low = [5, 69, 54];  // color of smallest datum
    var high = [151, 83, 34];   // color of largest datum

    // delta represents where the value sits between the min and max
    var delta = (feature.getProperty('average') - censusMin) /
        (censusMax - censusMin);

    var color = [];
    for (var i = 0; i < 3; i++) {
      // calculate an integer color based on the delta
      color[i] = (high[i] - low[i]) * delta + low[i];
    }

    // determine whether to show this shape or not
    var showRow = true;
    if (feature.getProperty('average') == null ||
        isNaN(feature.getProperty('average'))) {
      showRow = false;
    }

    var outlineWeight = 0.5, zIndex = 1;
    if (feature.getProperty('state') === 'hover') {
      outlineWeight = zIndex = 2;
    }

    var vcolour='hsl(' + color[0] + ',' + color[1] + '%,' + color[2] + '%)';
    if (feature.getProperty('select') ) {
      vcolour='grey';
    }

    return {
      strokeWeight: outlineWeight,
      strokeColor: '#fff',
      zIndex: zIndex,
      fillColor: vcolour,
      fillOpacity: 0.75,
      visible: showRow
    };
  }

  /**
   * Responds to the mouse-in event on a map shape (state).
   *
   * @param {?google.maps.MouseEvent} e
   */
  function mouseInToRegion(e) {
    // set the hover state so the setStyle function can change the border
    e.feature.setProperty('state', 'hover');

    var percent = (e.feature.getProperty('average') - censusMin) /
        (censusMax - censusMin) * 100;

    // update the label
    document.getElementById('data-label').textContent =
        e.feature.getProperty('postcode');
    document.getElementById('data-value').textContent =
        e.feature.getProperty('average').toLocaleString();
    document.getElementById('data-value1').textContent =
        e.feature.getProperty('amount').toLocaleString();
    document.getElementById('data-box').style.display = 'block';
    document.getElementById('data-caret').style.display = 'block';
    document.getElementById('data-caret').style.paddingLeft = percent + '%';
  }

  /**
   * Responds to the mouse-out event on a map shape (state).
   *
   * @param {?google.maps.MouseEvent} e
   */
  function mouseOutOfRegion(e) {
    // reset the hover state, returning the border to normal
    e.feature.setProperty('state', 'normal');
  }

  function mouseClick(e) {

   if(typeof(e.feature.getProperty('select'))== "undefined")
   {
     e.feature.setProperty('select',true);
     areaSelect.total=areaSelect.total+e.feature.getProperty('amount')
     areaSelect.areas.add(e.feature.getProperty('postcode') )
     var areas=[];
     for (var i of areaSelect.areas)
     { areas.push(i)}
     document.getElementById('areaslb').textContent =
         "total houses -"+areaSelect.total;
     document.getElementById('areasbr').href="p1?a="+areas+"&b="+document.getElementById('census-min').textContent;

     document.getElementById('a').value=JSON.stringify(areas);
     document.getElementById('b').value=areaSelect.total;



   }
   else
   {
     if(e.feature.getProperty('select') )
     {
       e.feature.setProperty('select',false);
       areaSelect.total=areaSelect.total-e.feature.getProperty('amount')
       areaSelect.areas.delete(e.feature.getProperty('postcode') )
       var areas=[];
       for (var i of areaSelect.areas)
       { areas.push(i)}
       document.getElementById('areaslb').textContent =
           "total houses -"+areaSelect.total+'  '+areas;
        document.getElementById('areasbr').href="p1?a="+areas+"&b="+document.getElementById('census-min').textContent;

        document.getElementById('a').value=JSON.stringify(areas);
        document.getElementById('b').value=areaSelect.total;
     }
     else
     {
       e.feature.setProperty('select',true);
       areaSelect.total=areaSelect.total+e.feature.getProperty('amount')
       areaSelect.areas.add(e.feature.getProperty('postcode') )
       var areas=[];
       for (var i of areaSelect.areas)
      { areas.push(i)}
       document.getElementById('areaslb').textContent =
           "total houses -"+areaSelect.total+'  '+areas;
       document.getElementById('areasbr').href="p1?a="+areas+"&b="+document.getElementById('census-min').textContent;

       document.getElementById('a').value=JSON.stringify(areas);
       document.getElementById('b').value=areaSelect.total;
     }

     console.log(e.feature.getProperty('select'));

   }


  }
