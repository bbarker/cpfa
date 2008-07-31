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

def PlotAllTP(gp, ltree, feature, withstr):
	data = []
	nodes = ltree.bfs("NotANode", ltree.root, ltree.findNode, True)	
	for nd in nodes:
		if nd != None:
			if nd.data != None:
				for tp in nd.data.time_points.keys():
					data.append([tp,nd.data.time_points[tp].get(feature)])
	gp.xlabel('time (minutes)')
	gp.ylabel(feature)
	gp.plot(data, with=withstr)			


def PlotAllTP2(gp, ltree, feature, withstr):
	data = []
	nodes = ltree.bfs("NotANode", ltree.root, ltree.findNode, True)	
	for nd in nodes:
		if nd != None:
			if nd.data != None:
				for tp in nd.data.time_points.keys():
					data.append([tp,nd.data.time_points[tp].get(feature)])
	gp.xlabel('time (minutes)')
	gp.ylabel(feature)
	gp.plot(data, with=withstr)			


def PlotDistrib2(gp, ltree, feature, ndigits):
	data = {}
	nodes = ltree.bfs("NotANode", ltree.root, ltree.findNode, True)
	threshold1 = 1
	threshold2 = 2
	count = 0
	for nd in nodes:
		if nd != None:
			if nd.data != None:
				for tp in nd.data.time_points.keys():
					if data.get(round(nd.data.time_points[tp].get(feature),ndigits)) != None:
						data[round(nd.data.time_points[tp].get(feature),ndigits)] += 1
					else:
						data[round(nd.data.time_points[tp].get(feature),ndigits)] = 1
	for k in data.keys():
		if k >= threshold1 and k < threshold2:	
			count += data[k] 
	print "count is: " + str(count)
	gp('set xrange [0:5]')
	gp.plot(data.items())

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


						

