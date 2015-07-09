<!---
Author : Gary Gilbert
Description: Custom tag wrapper for JFreeChart Java API - subtag JfreeSeries
Arguments:
seriesLabel - string
seriesColorHex - string (color in hex)
colorList - string (list of colors to apply to a series)
query - query containing the data to be passed to the parent tag
itemColumn - the columnname in the query that contains the category names or X value in an xy chart (scatter or time series)
valueColumn - the columnname in the query that contains the y values
seriesLineThickness - applies to line charts the thickness of the line in pixels.

Change History: 08.02.2008 - Added scatter chart type
													 - Broke out pie chart styling into own function
													 - Broke out bar/line chart styling into own function
													 - Created fucntion to build xy data sets from query
													 - Created fucntion to build defaultCategoryData sets from query
													 - Created function to build jfree Pie Data sets from query
													 - added CustomImageOutput function to allow the addition of the 'usemap' attribute to the generated image tag
								07.02.2008 - Initial charts added (bar/line)
 --->
<cfparam name="attributes.seriesLabel" type="string" default="">
<cfparam name="attributes.seriesColorHEX" type="string" default="">
<cfparam name="attributes.colorList" type="string" default="">
<cfparam name="attributes.itemColumn" type="string" default="">
<cfparam name="attributes.valueColumn" type="string" default="">
<cfparam name="attributes.query" type="query" >
<cfparam name="attributes.seriesLineThickness" type="integer" default="0">

<cfif thisTag.ExecutionMode eq "start">
	<cfset ancestors = getBaseTagList()>

	<cfif listLen(ancestors) eq 1>
	<!--- check to make sure that this tag is not used by itself --->
		<cfabort showerror="This tag must be nested within the jfreeChart custom tag"/>
	<cfelse>
	<!--- before passing the data to the parent check to see that the data being passed is valid for
	the chart type --->
		<cfset ChartType = GetBaseTagData(listGetAt(ancestors,2)).attributes.charttype>
		<cfswitch expression="#ChartType#">
			<cfcase value="scatter">
					<!--- I could potential save a lot of looping here and just check the first row values
					and error out on the parent...will have to test for speed
					TODO: test large datasets for slowdown when checking scatter plots --->
					<cfset thequery = attributes.query>
					<cfloop query="theQuery">
						<cfif not isnumeric(evaluate("theQuery.#attributes.itemColumn#"))>
							<Cfabort showerror="Scatter charts require both the <em>itemColumn</em> and the <em>valueColumn</em> to be numeric values">
						</cfif>
					</cfloop>
		</cfcase>
		</cfswitch>
		<cfassociate baseTag="cf_jFreeChart" dataCollection='data'/>
	</cfif>
</cfif>



