#!/Applications/sage/sage 
# vim:set syntax=python:
load utils.sage
load celldiv.sage
import sys
import Gnuplot
from path import path
#import re
Int = Integer #for shorthand purposes... 

def PlotCDFeature(gp, ltree, nd, feature):
	#nd = ltree.lookup(ltree.root, nucleus)
	data = []	
	if nd.data != None:
		for tp in nd.data.time_points.keys():
			data.append([tp,nd.data.time_points[tp][feature]])
	if nd.left.data != None:
		for tp in nd.left.data.time_points.keys():
			data.append([tp,nd.left.data.time_points[tp][feature]])
	if nd.right.data != None:
		for tp in nd.right.data.time_points.keys():
			data.append([tp,nd.right.data.time_points[tp][feature]])
	gp.plot(data)	

def PlotCDLookup(gp, ltree, nucleus, feature):
	nd = ltree.lookup(ltree.root, nucleus)
	PlotCDFeature(gp, ltree, nd, feature)

def PlotAllTP(gp, ltree, feature):
	data = []
	nodes = ltree.bfs("NotANode", ltree.root, ltree.findNode, True)	
	for nd in nodes:
		if nd != None:
			if nd.data != None:
				for tp in nd.data.time_points.keys():
					data.append([tp,nd.data.time_points[tp].get(feature)])
	gp.xlabel('time (minutes)')
	gp.ylabel(feature)
	gp.plot(data)			

def PlotDistrib(gp, ltree, feature, ndigits):
	data = {}
	nodes = ltree.bfs("NotANode", ltree.root, ltree.findNode, True)
	for nd in nodes:
		if nd != None:
			if nd.data != None:
				for tp in nd.data.time_points.keys():
					if data.get(round(nd.data.time_points[tp].get(feature),ndigits)) != None:
						data[round(nd.data.time_points[tp].get(feature),ndigits)] += 1
					else:
						data[round(nd.data.time_points[tp].get(feature),ndigits)] = 1
	gp.plot(data.items())


						

