#!/Applications/sage/sage 
# vim:set syntax=python:
load utils.sage
load celldiv.sage
import datetime
import sys
import Gnuplot
import commands
from path import path
#import re
Int = Integer #for shorthand purposes... 

def PlotCDFeature(gplt, ltree, nd, feature):
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
	gplt.plot(data)	

def PlotCDLookup(gplt, ltree, nucleus, feature):
	nd = ltree.lookup(ltree.root, nucleus)
	PlotCDFeature(gplt, ltree, nd, feature)

def PlotAllTP(bench, feature, ltreelist=None, withstr='', visit='all'):
	data = [] 
	xmin = Infinity 
	xmax = -Infinity
	if ltreelist == None:
		ltreelist = bench.embryo.values()
	for ltree in ltreelist:
		nodes = None 
		if visit == 'all':
			nodes = ltree.bfs("NotANode", ltree.root, ltree.findNode, True)	
		elif visit == 'one_child':
			nodes = ltree.bfs("NotANode", ltree.root, ltree.aChild, True)
		for nd in nodes:
			if nd != None:
				if nd.data != None:
					for tp in nd.data.time_points.keys():
						data.append([tp,nd.data.time_points[tp].get(feature)])
						if tp < xmin:
							xmin = tp
						if tp > xmax:
							xmax = tp
	bench.gplt('set xrange[' + str(xmin) + ':' + str(xmax) + ']')
	bench.gplt.xlabel('time (minutes)')
	bench.gplt.ylabel(feature.replace('_',' '))
	if withstr == '':
		bench.gplt.plot(Gnuplot.Data(data))
	else:
		bench.gplt.plot(Gnuplot.Data(data, with=withstr))			


def PlotLminDist(gplt, ltree):
	radii = []
	Lmin_o_2 = []
	data = []
	nodes = ltree.bfs("NotANode", ltree.root, ltree.findNode, True)	
	for nd in nodes:
		if nd != None:
			if nd.data != None:
				for tp in nd.data.time_points.keys():
					data.append([tp,RR(nd.data.time_points[tp].get('L_min')/nd.data.time_points[tp].get('diameter'))])
	gplt.xlabel('time (minutes)')
	gplt.ylabel('length ratio of L_{min}/diameter')
	gplt('set xrange [0:199]')
	gplt.plot(Gnuplot.Data(data, with='points lc rgb "red"'))

def PlotLRatio(bench, ndigits, ltreelist=None):
	if ltreelist == None:
		ltreelist = bench.embryo.values()
	feature='l/(L_min/2)'
	data = {}
	errdata = {}
	threshold1 = 1
	threshold2 = 2
	for ltree in ltreelist:	
		nodes = ltree.bfs("NotANode", ltree.root, ltree.findNode, True)
		for nd in nodes:
			if nd != None:
				if nd.data != None:
					for tp in nd.data.time_points.keys():
						if nd.data.time_points[tp].get('diam_overlap_err') == False:
							if data.get(round(nd.data.time_points[tp].get(feature),ndigits)) != None:
								data[round(nd.data.time_points[tp].get(feature),ndigits)] += 1
							else:
								data[round(nd.data.time_points[tp].get(feature),ndigits)] = 1
						else:
							if errdata.get(round(nd.data.time_points[tp].get(feature),ndigits)) != None:
								errdata[round(nd.data.time_points[tp].get(feature),ndigits)] += 1
							else:
								errdata[round(nd.data.time_points[tp].get(feature),ndigits)] = 1
	errcount = 0
	count = 0
	if errdata.get(RR('NaN')):
		del errdata[RR('NaN')]
	if data.get(RR('NaN')):
		del data[RR('NaN')]
	for k in errdata.keys():
		errcount += errdata[k]
	for k in data.keys():
		count += data[k]
	print "Non-error count is: " + str(count) + "\n"
	print "Error count is: " + str(errcount) + "\n"
	print "Percent Error is: " + str(RR(100*errcount/(errcount+count)))
	bench.gplt.xlabel(feature.replace('_',' '))
	bench.gplt.ylabel('frequency')
	xmin = min(data.keys())-1	
	xmax = max(data.keys())+1
	bench.gplt('set xrange[' + str(xmin) + ':' + str(xmax) + ']')
	bench.gplt('set key top right')
	bench.gplt.plot(Gnuplot.Data(data.items(),with='points lc rgb "cyan"',title="Lmin >= r1 + r2"), \
	Gnuplot.Data(errdata.items(),with='points lc rgb "red"', title="Lmin < r1 + r2"))
	return errdata
	#gplt.plot(Gnuplot.Data(data.items(),with='lines'), Gnuplot.Data(errdata.items(),with='lines'))

def PlotDistrib(gplt, ltree, feature, ndigits):
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
	gplt.xlabel(feature.replace('_',' '))
	gplt.ylabel('frequency')
	gplt.plot(data.items())


def GenReport(bench):
	reportdir = 'report' + rm_symbols_datetime.sub('',datetime.datetime.now().isoformat())
	os.mkdir(path.joinpath(path(bench.CELLDIV_DIR), reportdir))
	bench.gplt('set term postscript enhanced color landscape')
	bench.gplt('set output "' + path.joinpath(path(bench.CELLDIV_DIR), reportdir,'000000000000000.ps').strip() + '"')
	bench.gplt('set multiplot layout 4,2 title "All Embryos"')
	PlotAllTP(bench, 'diameter', None, 'lines')
	PlotAllTP(bench, 'total_gfp', None, 'lines')
	PlotAllTP(bench, 'diameter_fold')
	PlotAllTP(bench, 'gfp_fold')
	PlotLRatio(bench, 2, None) 
	PlotAllTP(bench, 'sister-self_centroid_dist_from_mother', None, 'lines', 'one_child')
	PlotAllTP(bench, 'ratio_diam_sisterdiam', None, 'lines', 'one_child')
	PlotAllTP(bench, 'ratio_gfp_sistergfp', None, 'lines', 'one_child')
	bench.gplt('unset multiplot')
	for emb in bench.embryo.keys():
		bench.gplt('set term postscript enhanced color landscape')
		bench.gplt('set output "' + path.joinpath(path(bench.CELLDIV_DIR), reportdir, emb +'.ps').strip() + '"')
		bench.gplt('set multiplot layout 4,2 title "' + emb + '"')
		PlotAllTP(bench, 'diameter', [bench.embryo[emb]], 'lines')
		PlotAllTP(bench, 'total_gfp', [bench.embryo[emb]], 'lines')
		PlotAllTP(bench, 'diameter_fold', [bench.embryo[emb]])
		PlotAllTP(bench, 'gfp_fold', [bench.embryo[emb]])
		PlotLRatio(bench, 2, [bench.embryo[emb]]) 
		PlotAllTP(bench, 'sister-self_centroid_dist_from_mother', [bench.embryo[emb]], 'lines', 'one_child')
		PlotAllTP(bench, 'ratio_diam_sisterdiam', [bench.embryo[emb]], 'lines', 'one_child')
		PlotAllTP(bench, 'ratio_gfp_sistergfp', [bench.embryo[emb]], 'lines', 'one_child')
		bench.gplt('unset multiplot')
	#make this system agnostic later
	commands.getoutput('/usr/bin/psjoin ' + reportdir + '/*.ps > ' + reportdir + '.ps') 
	commands.getoutput('rm -fr ' + reportdir)

