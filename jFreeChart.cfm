<cfsilent>
<!---
Author : Gary Gilbert
Description: Custom tag wrapper for JFreeChart Java API
Arguments:
chartType - string (bar,pie,line etc)
width - integer (pixles)
height - integer (pixles)
backgroundColorHEX - string {hex color value example CC0000}
rangeGridlineColorHex - string {hex color value}
createImageMap -boolean {returns an html image map snippet}
returnChartAsImage - boolean

Change History: 20.02.2008 - Corrected height/width mixup
							- added support for earlier versions of Coldfusion (removed <cfimage> tag and imagenew functionality)
							- added chachedirectory /maxCacheSize attributes to support earlier cf versions
							- added check for chachedirectory attribute (must naturally exist before trying to write to the directory.
							- added cfsilent around functions
							- made small change to customImageOutput function
				12.02.2008	- Added Gantt chart type
							- Added child tag jfTaskSeries to support Gantt chart type
							- Added show legend attribute awareness
							- Added height and width attribute awareness
							- Added validation to attributes (height,width,show legend)
				08.02.2008 	- Added scatter chart type
							- Broke out pie chart styling into own function
							- Broke out bar/line chart styling into own function
							- Created fucntion to build xy data sets from query
							- Created fucntion to build defaultCategoryData sets from query
							- Created function to build jfree Pie Data sets from query
							- added CustomImageOutput function to allow the addition of the 'usemap' attribute to the generated image tag
				07.02.2008 - Initial charts added (bar/line)
 --->
<cfparam name="attributes.chartType" type="string" default="">
<cfparam name="attributes.title" type="string" default="">
<cfparam name="attributes.CategoryAxisLabel" type="string" default="">
<cfparam name="attributes.CategoryValueLabel" type="string" default="">
<cfparam name="attributes.width" type="numeric" default=0>
<cfparam name="attributes.height" type="numeric" default=0>
<cfparam name="attributes.backgroundColorHEX" type="string" default="FFFFFF">
<cfparam name="attributes.rangeGridlineColorHEX" type="string" default="000000">
<cfparam name="attributes.createImageMap" type="boolean" default="false">
<cfparam name="attributes.returnChartAsImage" type="boolean" default="true">
<cfparam name="attributes.showLegend" type="boolean" default="true">
<cfparam name="attributes.showToolTips" type="boolean" default="false">
<cfparam name="attributes.showLabels" type="boolean" default="false">
<cfparam name="attributes.showMarkers" type="boolean" default="true">
<cfparam name="attributes.cacheDirectory" type="string" default="">
<cfparam name="attributes.maxCacheSize" type="numeric" default="10">


<!--- if you add support for another chart type be sure to add it to the chartType variable,
the validation uses this list to validate the charttype argument --->
<cfset variables.chartTypes="bar,line,pie,scatter,gantt">
<!--- two possible child tags for the parent --->
<cfset variables.childTags ="JfSeries, JfTaskSeries">
<!---
Function:ClearCacheDir
Purpose: get the number of files contained in the specified cache directory and determines if the maximum cache size has been reached
				if so it deletes the oldest file.
 --->
<cffunction name="clearCacheDir" output="false" returntype="void" access="private">

	<cfdirectory action="list" directory="#expandpath(attributes.cacheDirectory)#" name="files" filter="*.png" sort="datelastmodified asc">
	<cfif files.recordcount gt attributes.maxCacheSize>

	<cfloop query="files" startrow="#attributes.maxCacheSize#" endrow="#files.recordcount#">
		<cffile action="delete" file="#directory#\#name#">
	</cfloop>
	</cfif>
</cffunction>
<!---
custom image output function idea from Ben Nadel
allows you to add additional attributes to the writeToBrowser action of the cfimage tag
--->
<cffunction name="customImageOutput" output="false" returntype="string" access="private">
	<cfargument name="Image" type="any" required="true"/>
	<cfargument name="useMapName" type="string" required="false"/>

		<cfset files = clearCacheDir()>
		<cfset imageIO = CreateObject("java", "javax.imageio.ImageIO")>
		<cfset filename=createuuid()>
		<cfset outFile = CreateObject("java", "java.io.File")>
		<cfset outFile.init("#expandpath(attributes.cachedirectory)#\#filename#.png")>
		<cfset imageIO.write(myImage, "png", outFile)>
		<cfsaveContent variable="image">
<img src="<cfoutput>#attributes.cacheDirectory#/#filename#.png</cfoutput>" <cfif isdefined("useMapName")>usemap="#<cfoutput>#arguments.useMapName#</cfoutput>"</cfif> border="0">
		</cfsaveContent>
	<cfreturn image/>
</cffunction>
<!---
Function:createTaskSeriesDataSet
Purpose: The task series dataset is specific for the gantt chart type.
 --->
<cffunction name="createTaskSeriesDataSet" output="false" returntype="void" access="private">

<!--- set up the series data types that we need for the task series --->
		<cfset variables.dataset = createObject("java","org.jfree.data.gantt.TaskSeriesCollection")>
		<cfset variables.taskSeries = arrayNew(1)>
		<cfloop from="1" to="#arraylen(thisTag.data)#" index="i">
			<!--- loop through the array grabbing the query data and adding it to the dataset--->
			<cfset variables.taskSeries[#i#] = createObject("java","org.jfree.data.gantt.TaskSeries").init(thisTag.data[i].seriesLabel)><!--- create the task --->
			<cfset theQuery=thisTag.data[i].query>
			<cfloop query="theQuery">
				<!--- create the task time span --->
					<cfset SimpleTimePeriod= createObject("java","org.jfree.data.time.SimpleTimePeriod").init(createObject("java","java.util.Date").init(evaluate("#thisTag.data[i].StartDateColumn#")),createObject("java","java.util.Date").init(evaluate("#thisTag.data[i].endDateColumn#")))>
					<!--- add the task to the task series --->
				<cfset mytask = createObject("java","org.jfree.data.gantt.Task").init(evaluate("#thisTag.data[i].TaskNameColumn#"),simpleTimePeriod)>
				<cfset mytask.setPercentComplete(javacast("double","#evaluate("#thisTag.data[i].PercentCompleteColumn#")#"))>
				<cfset variables.taskSeries[#i#].add(#mytask#)>
					<cfset mytask="">
					<cfset simpleTimePeriod="">
			</cfloop>
			<cfset variables.dataset.add(variables.taskSeries[#i#])>
		</cfloop>
</cffunction>
<!---
Function Name: createDefaultCategoryDataSet
Purpose: Translate the data passed by the series tag into a Java dataset for use with:
					MultiplePieChar, Bar, Line, etc
 --->
<cffunction name="createDefaultCategoryDataSet" output="false" returntype="void" access="private">

	<cfset variables.dataset = createObject("java","org.jfree.data.category.DefaultCategoryDataset")>
	<cfloop from="1" to="#arraylen(thisTag.data)#" index="i">
			<!--- loop through the array grabbing the query data and adding it to the dataset--->
			<cfset theQuery=thisTag.data[i].query>
			<cfloop query="theQuery">
					<cfset variables.dataset.addValue(javacast('string','#evaluate('#thisTag.data[i].valueColumn#')#'),"#thisTag.data[i].seriesLabel#","#evaluate("#thisTag.data[i].itemColumn#")#")>
			</cfloop>
		</cfloop>
</cffunction>

<!---
Function Name: createPieDataSet
Purpose: Translates the single series data into a dataset type that the pie chart can use
 --->
<cffunction name="createPieDataSet" output="false" returntype="void" access="private">
	<cfset variables.dataset = createObject("java","org.jfree.data.general.DefaultPieDataset")>
	<cfloop from="1" to="#arraylen(thisTag.data)#" index="i">
			<!--- loop through the array grabbing the query data and adding it to the dataset--->
			<cfset theQuery=thisTag.data[i].query>
			<cfloop query="theQuery">
					<cfset variables.dataset.setValue(javacast('string','#evaluate("#thisTag.data[i].itemColumn#")#'),"0#evaluate('#thisTag.data[i].valueColumn#')#")>
			</cfloop>
		</cfloop>

</cffunction>
<!---
Function Name: createXYDataSet
Purpose: Translates the single series data into a XY dataset type (scatter/line etc)
 --->
<cffunction name="createXYDataSet" output="false" returntype="void" access="private">
	<cfset variables.dataset = createObject("java","org.jfree.data.xy.XYSeriesCollection")>
	<cfset variables.series = arrayNew(1)>
	<cfloop from="1" to="#arraylen(thisTag.data)#" index="i">
			<!--- loop through the array grabbing the query data and adding it to the dataset--->
			<cfset variables.series[#i#]= createObject("java","org.jfree.data.xy.XYSeries").init('#thisTag.data[i].seriesLabel#')>
			<cfset theQuery=thisTag.data[i].query>



			<cfloop query="theQuery">
			<cfset xyItem = createObject("java","org.jfree.data.xy.XYDataItem").init(evaluate("#thisTag.data[i].itemColumn#"),evaluate('#thisTag.data[i].valueColumn#'))>

					<cfset variables.series[#i#].add(xyItem)>
			</cfloop>
			<cfset variables.dataset.addSeries(variables.series[#i#])>
		</cfloop>

</cffunction>

<!---
Function Name: styleBarLineChart
Purpose: Styles the line and bar charts based on attributes specified in the child tag
 --->
<cffunction name="styleBarLineChart" output="false" returntype="void" access="private">
	<cfargument name="chartType" type="string" required="true">
	<cfscript>
			variables.Color = createObject("java","java.awt.Color");  //used to create colors
		 	plot = chart.getPlot();  //get the chart plotter
			plot.setBackgroundPaint(Color.white); //set the chart background - TODO:allow attribute passing
			plot.setRangeGridlinePaint(Color.lightGray); //set the grid lines - TODO:allow attribute passing
			renderer = plot.getRenderer(); //gets the item renderer
			if (attributes.charttype eq "bar"){
				renderer.setItemMargin(0.0);//sets the margin between the series barchart only do this by default to take up less space
			}
			if (attributes.charttype eq "line" and attributes.showmarkers){

				renderer.setBaseItemLabelGenerator(StandardCategoryItemLabelGenerator);
				renderer.setBaseShapesVisible(true);
				renderer.setDrawOutlines(true);
				renderer.setUseFillPaint(true);
				renderer.setBaseFillPaint(Color.white);

			}
			//send in true to show the series lables
			if(attributes.showlabels){
				for(x=0;x lt arraylen(thisTag.data);x=x+1){
					renderer.setSeriesItemLabelsVisible(javacast("int","#x#"),javacast("boolean","true"),javacast("boolean","false"));
				}
			}
			//loop through series and apply attributes
			for(x=0;x lt arraylen(thisTag.data);x=x+1){
				if (len(thisTag.data[x+1].seriesColorHEX)){
					renderer.setSeriesPaint(javacast("int","#x#"),createObject("java","java.awt.Color").decode("0x#thisTag.data[x+1].seriesColorHEX#"));
				}
				if (thisTag.data[x+1].seriesLineThickness){
						basicStroke1 = createObject("java","java.awt.BasicStroke").init("#thisTag.data[x+1].seriesLineThickness#");
						renderer.setSeriesStroke(javacast("int","#x#"), basicStroke1);
				}
			}
	</cfscript>
</cffunction>

<!---
Function Name: StylePieChart
Purpose: Determines if the chart to be created is a multiple pie chart or a single pie chart by the
				number of datasets passed by the use of the series child tags.
 --->
<cffunction name="stylePieChart" output="false" returntype="void" access="private">
	<cfscript>
		//check to see if colorList from the series data is set
		plot = chart.getPlot();
	</cfscript>
		<cfloop from="1" to="#arraylen(thisTag.data)#" index="i">
		<cfset theQuery=thisTag.data[i].query>
			<cfset x=0>
			<cfloop query="theQuery">
				<cftry>
					<cfset x= x +1>
					<cfset theColor = listGetAt(thisTag.data[i].colorList,x)>
					<cfset plot.setSectionPaint('#evaluate("#thisTag.data[i].itemColumn#")#',createObject("java","java.awt.Color").decode("0x#theColor#"))>
				<cfcatch type="any"></cfcatch>
				</cftry>
			</cfloop>
		</cfloop>
</cffunction>
<!---
Function Name: createBarChart
Purpose: Determines if the chart to be created is a multiple pie chart or a single pie chart by the
				number of datasets passed by the use of the series child tags.
 --->
<cffunction name="createBarChart" output="false" returntype="void" access="private">
	<cfscript>
		createDefaultCategoryDataSet();
		chart = variables.chartFactory.createBarChart("#attributes.title#","#attributes.CategoryAxisLabel#","#attributes.categoryValueLabel#",variables.dataset,PlotOrientation.VERTICAL,attributes.showLegend, true, false);
		styleBarLineChart('Bar');
	</cfscript>
</cffunction>
<!---
Function Name: createLineChart
Purpose: Determines if the chart to be created is a multiple pie chart or a single pie chart by the
				number of datasets passed by the use of the series child tags.
 --->
<cffunction name="createLineChart"  output="false" returntype="void" access="private">

	<cfscript>
		createDefaultCategoryDataSet();
		chart = variables.chartFactory.createLineChart("#attributes.title#","#attributes.CategoryAxisLabel#","#attributes.categoryValueLabel#",variables.dataset,PlotOrientation.VERTICAL,attributes.showLegend, true, false);
		styleBarLineChart('Line');
	</cfscript>
</cffunction>

<!---
Function Name: createPieChart
Purpose: Determines if the chart to be created is a multiple pie chart or a single pie chart by the
				number of datasets passed by the use of the series child tags.
 --->
<cffunction name="createPieChart" output="false" returntype="void" access="private">
<cfset var multiplePie = false>

<cfscript>
	if (arraylen(thisTag.data) gt 1){
		createDefaultCategoryDataSet();
		multiplePie = true;
	}else{
		createPieDataSet();
	}
	if (multiplePie){
		tableOrder = createObject("java","org.jfree.util.TableOrder");
		chart = variables.chartFactory.createMultiplePieChart("#attributes.title#",variables.dataset,tableOrder.BY_COLUMN,attributes.showLegend, true, false);
	}else{
		chart = variables.chartFactory.createPieChart("#attributes.title#",variables.dataset,true, true, false);
	}
	stylePieChart();
</cfscript>
</cffunction>
<!---
Function Name: createScatterChart
Purpose: Responsible for creating the scatter chart.
 --->
<cffunction name="createScatterChart" output="false" returntype="void" access="private">

	<cfscript>
		plotOrientation= createObject("java","org.jfree.chart.plot.PlotOrientation");
		createXYDataSet();
		chart = variables.chartFactory.createScatterPlot("#attributes.title#",attributes.categoryAxisLabel,attributes.categoryValueLabel,variables.dataset,PlotOrientation.VERTICAL,attributes.showLegend, true, false);
		plot = chart.getPlot();
		numberAxis=createObject("java","org.jfree.chart.axis.NumberAxis");
		rangeAxis = plot.getRangeAxis();
		rangeAxis.setStandardTickUnits(NumberAxis.createIntegerTickUnits());
		DomainAxis = plot.getDomainAxis();
		DomainAxis.setStandardTickUnits(NumberAxis.createIntegerTickUnits());
	</cfscript>

</cffunction>
<!---
Function Name: createGanttChart
Purpose: Responsible for creating the Gantt chart.
 --->
<cffunction name="createGanttChart" output="false" returntype="void" access="private">
	<cfscript>
		createTaskSeriesDataSet();
		chart = variables.chartFactory.createGanttChart(attributes.title,attributes.categoryAxisLabel,attributes.categoryValueLabel,variables.dataset,attributes.showLegend,true,false);
		plot = chart.getPlot();
		renderer = plot.getRenderer();
		renderer.setItemMargin(0.1);
		//set the color of the series
			for(x=0;x lt arraylen(thisTag.data);x=x+1){
				if (len(thisTag.data[x+1].seriesColorHEX)){
					renderer.setSeriesPaint(x,createObject("java","java.awt.Color").decode("0x#thisTag.data[x+1].seriesColorHEX#"));
				}
			}
	</cfscript>
</cffunction>
</cfsilent>
<!--- ####################### END FUNCTIONS ######################## --->
<cfif thisTag.HasEndTag eq false>
	<cfabort showerror="jFreeChart tag requires an end tag">
</cfif>

<cfswitch expression="#thisTag.ExecutionMode#">
	<cfcase value="start">
<!--- ********************************************************
Attribute Validation:

1) CacheDirectory - In order to support earlier versions of CF cacheDirectory is required
2) ChartType - Check to make sure that the chart type requested is one of the support chart types
3) height/width - height and width should be positive numeric values
************************************************************** --->

	<!--- check the cache directory if its not empty make sure the directory exists --->
		<cfif attributes.cacheDirectory neq ''>
			<cfif not directoryExists(expandpath(attributes.cachedirectory))>
				<cfabort showerror="Specified Directory does not exist">
			</cfif>
		<cfelse>
				<cfabort showerror="cacheDirectory is required and must be web-accessible and relative to the web-root."/>
		</cfif>
	<!--- Validate that the chart type is one of the supported chart types --->
			<cfif not listFindNoCase(variables.chartTypes,attributes.chartType)>
				<cfabort showerror="chartType must be one of:<em>#variables.chartTypes#</em> "/>
			<cfelse>
				<!--- make sure the first letter is capitalized --->
				<cfset attributes.chartType = ucase(left(attributes.charttype,1)) & right(attributes.charttype,len(attributes.charttype)-1)>
			</cfif>

			<cfif attributes.height lte 0>
				<cfabort showerror="<em>Height</em> attribute must be <em>numeric</em> in Pixels">
			</cfif>
			<cfif attributes.width lte 0>
				<cfabort showerror="<em>Width</em> attribute must be <em>numeric</em> in Pixels">
			</cfif>
		<cfset mapstring="">
	<!--- set up the base java objects --->
		<cfscript>
			variables.chartFactory = createObject("java","org.jfree.chart.ChartFactory");
			variables.jfreeChart= createObject("java","org.jfree.chart.JFreeChart");
			variables.PlotOrientation = createObject("java","org.jfree.chart.plot.PlotOrientation");
			if (attributes.createImageMap){
				variables.ImageMapUtilities = createObject("java","org.jfree.chart.imagemap.ImageMapUtilities");
				variables.ChartRenderingInfo= createObject("java","org.jfree.chart.ChartRenderingInfo");
				variables.StandardEntityCollection= createObject("java","org.jfree.chart.entity.StandardEntityCollection");
				info = ChartRenderingInfo.init(StandardEntityCollection.init());
			}
			if (attributes.chartType eq "line"){
			StandardCategoryItemLabelGenerator= createObject("java","org.jfree.chart.labels.StandardCategoryItemLabelGenerator").init();
			}
		</cfscript>
	</cfcase>
	<cfcase value="end">
	<!--- make sure it has a child tag --->
	<!--- don't bother making the chart if there isnt any data meaning no child tags have been specified --->
		<cfif not isDefined("thisTag.data")>
			<cfabort showerror="JfreeChart requires one of <em>#variables.childtags#</em> child tags">
		</cfif>
			<!--- we have data from our child tags build the chart--->
			<cfscript>
			evaluate("create#attributes.chartType#Chart()");
			if (attributes.createImageMap){
				mapName = createUUID();
			//render the imagemap with the image if requested
			myImage = chart.createBufferedImage(attributes.height,attributes.width,info);
			mapstring = ImageMapUtilities.getImageMap(mapName,info);
			}else{
				//render the image without the image map
			myImage = chart.createBufferedImage(attributes.height,attributes.width);
			}
			</cfscript>
			<!--- if the user wants to have tooltips then we need to add the usemap attribute to the <img> tag and output the imagemap returned
			by jfree chart engine --->
			<cfif attributes.createImageMap>
					<cfoutput>#mapstring#
					#customImageOutput(myImage,mapName)#
					</cfoutput>
			<cfelse>
			<!---write the image to the browser, may be a good idea in the future to give user the option of saving the
			generated image to a file, only if they don't want tooltips/createImageMap  --->
				<cfoutput>
					#customImageOutput(myImage)#
				</cfoutput>
			</cfif>
	</cfcase>
</cfswitch>
