#!/Applications/sage/sage 
# vim:set syntax=python:
load utils.sage
load celldiv.sage
import datetime
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

def PlotAllTP(gp, ltree, feature, withstr=''):
	data = {} 
	nodes = ltree.bfs("NotANode", ltree.root, ltree.findNode, True)	
	for nd in nodes:
		if nd != None:
			if nd.data != None:
				for tp in nd.data.time_points.keys():
					data[tp]=nd.data.time_points[tp].get(feature)
	xmin = min(data.keys())-1	
	xmax = max(data.keys())+1
	gp('set xrange[' + str(xmin) + ':' + str(xmax) + ']')
	gp.xlabel('time (minutes)')
	gp.ylabel(feature.replace('_',' '))
	if withstr == '':
		gp.plot(Gnuplot.Data(data.items()))
	else:
		gp.plot(Gnuplot.Data(data.items(), with=withstr))			


def PlotLminDist(gp, ltree):
	radii = []
	Lmin_o_2 = []
	data = []
	nodes = ltree.bfs("NotANode", ltree.root, ltree.findNode, True)	
	for nd in nodes:
		if nd != None:
			if nd.data != None:
				for tp in nd.data.time_points.keys():
					data.append([tp,RR(nd.data.time_points[tp].get('L_min')/nd.data.time_points[tp].get('diameter'))])
	gp.xlabel('time (minutes)')
	gp.ylabel('length ratio of L_{min}/diameter')
	gp('set xrange [0:199]')
	gp.plot(Gnuplot.Data(data, with='points lc rgb "red"'))


def PlotLRatio(gp, ltree, ndigits):
	feature='l/(L_min/2)'
	data = {}
	errdata = {}
	nodes = ltree.bfs("NotANode", ltree.root, ltree.findNode, True)
	threshold1 = 1
	threshold2 = 2
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
	gp.xlabel(feature.replace('_',' '))
	gp.ylabel('frequency')
	xmin = min(data.keys())-1	
	xmax = max(data.keys())+1
	gp('set xrange[' + str(xmin) + ':' + str(xmax) + ']')
	gp('set key top right')
	gp.plot(Gnuplot.Data(data.items(),with='points lc rgb "cyan"',title="Lmin >= r1 + r2"), \
	Gnuplot.Data(errdata.items(),with='points lc rgb "red"', title="Lmin < r1 + r2"))
	gp.save('/Users/anthony/gnuplot.save')
	return errdata
	#gp.plot(Gnuplot.Data(data.items(),with='lines'), Gnuplot.Data(errdata.items(),with='lines'))

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
	gp.xlabel(feature.replace('_',' '))
	gp.ylabel('frequency')
	gp.plot(data.items())

def PlotAllSymmetricValue(

def GenReport(bench):
	reportdir = 'report' + rm_symbols_datetime.sub('',datetime.datetime.now().isoformat())
	os.mkdir(path.joinpath(path(bench.CELLDIV_DIR), reportdir))
	for emb in bench.embryo.keys():
		bench.gp('set term postscript enhanced color landscape')
		bench.gp('set output "' + path.joinpath(path(bench.CELLDIV_DIR), reportdir, emb +'.ps').strip() + '"')
		bench.gp('set multiplot layout 3,2 title "' + emb + '"')
		PlotAllTP(bench.gp, bench.embryo[emb], 'diameter','lines')
		PlotAllTP(bench.gp, bench.embryo[emb], 'total_gfp','lines')
		PlotAllTP(bench.gp, bench.embryo[emb], 'diameter_fold')
		PlotAllTP(bench.gp, bench.embryo[emb], 'gfp_fold')	
		PlotLRatio(bench.gp, eb.embryo[emb], 2) 
		PlotAllTP(bench.gp, bench.embryo[emb], 'sister-self_centroid_dist_from_mother','lines') 
		bench.gp('unset multiplot')
		#bench.gp.hardcopy(path.joinpath(path(bench.CELLDIV_DIR), reportdir, emb +'.ps'))
	#bench.gp('set term ' + Gnuplot.gp.GnuplotOpts.default_term)  

def nd_wo_parent(ltree):
	nodes = ltree.bfs("NotANode", ltree.root, ltree.findNode, True)	
	count = 0
	for nd in nodes:
		if nd.data != None:
			if nd.parent.data == None:
				count += len(nd.data.time_points.keys())
	print "nuclei w/o parent tp count: " + str(count)
	return count			

def l_eq_neg1(ltree):
	nodes = ltree.bfs("NotANode", ltree.root, ltree.findNode, True)
	count = 0
	for nd in nodes:
		if nd.data != None:
			for tp in nd.data.time_points.keys():
				if nd.data.time_points[tp]['l'] <= 0:
					print nd.data.time_points[tp]
					count +=1
	return count
