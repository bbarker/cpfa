#!/Applications/sage/sage 
# vim:set syntax=python:
load utils.sage
load celldiv.sage
import datetime
import sys
import Gnuplot
import commands
from path import path
from scipy import polyfit

#import re
Int = Integer #for shorthand purposes... 

def normLinearData(data_in):
	data_out = []
	(ar,br) = polyfit([x[0] for x in data], [x[1] for x in data], 1)
	x0 = min([x[0] for x in data])
	xf = max([x[0] for x in data])
	def f_a(x):
		return RR(ar*x+br)
	alpha = 0
	f_x0 = f_a(x0)
	f_xf = f_a(xf)
	if ar >= 0:
		alpha = f_xf - f_x0 
	else:
		alpha = f_x0 - f_xf
	def f_c(x):
		return RR((br-alpha)-ar*x)
	for datum in data_in:
		data_out.append( [datum[0], f_c(datum[1])] )
	print data_out
	return data_out
	
def linewrap(text,linelen):
	wrapped = ''
	for i in range(linelen, len(text)+linelen, linelen):
		wrapped += text[i-linelen:i].rjust(linelen,' ') + "\n"
	return wrapped
	
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

def PlotAllTP(bench, feature, ltreelist=None, withstr='points pointtype 3', visit='all'):
	data = {}
	count = {} 
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
						if nd.data.time_points[tp].get(feature) != None:
							if data.get(tp) != None:
								data[tp] += nd.data.time_points[tp].get(feature)
								count[tp] += 1
							else:
								data[tp] = nd.data.time_points[tp].get(feature)
								count[tp] = 1
	#data_norm = dict(normLinearData(data.items()))
	xmin = min(data.keys())
	xmax = max(data.keys())
	for tp in data.keys():
		if data[tp] != None and data[tp] != RR('NaN'):
			data[tp] = data[tp]/count[tp]	
	bench.gplt('set xrange[' + str(xmin) + ':' + str(xmax) + ']')
	bench.gplt.xlabel('time (minutes)')
	#ylab = linewrap('mean ' + feature.replace('_',' '), 18)
	ylab = 'mean ' + feature.replace('_',' ')
	bench.gplt('set ylabel "' + ylab + '" font "Helvetica,10"')
	#bench.gplt.ylabel('mean ' + feature.replace('_',' '))
	if withstr == '':
		bench.gplt.plot(Gnuplot.Data(data.items()))
	#	bench.gplt.replot(Gnuplot.Data(data_norm.itmems()))
	else:
		bench.gplt.plot(Gnuplot.Data(data.items(), with=withstr))			
	#	bench.gplt.replot(Gnuplot.Data(data_norm.itmems(), with=withstr))


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
	gplt.ylabel('length ratio of L_{min}/diameter font "Helvetica,13"')
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
						if nd.data.time_points[tp].get(feature) != None:
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
	bench.gplt('set ylabel "frequency" font "Helvetica,10"')
	xmin = min(data.keys())-1	
	xmax = max(data.keys())+1
	bench.gplt('set xrange[' + str(xmin) + ':' + str(xmax) + ']')
	bench.gplt('set key top right')
	bench.gplt.plot(Gnuplot.Data(data.items(),with='points pt 3 lc rgb "cyan"',title="Lmin >= r1 + r2"), \
	Gnuplot.Data(errdata.items(),with='points pt 4 lc rgb "red"', title="Lmin < r1 + r2"))
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

def TreeNavigate(ltree, node):
	nd = None
	if isinstance(node,type(ltree.root)):
		nd = node
	elif isinstance(node,type('c')):
		nd = ltree.lookup(ltree.root,node)
		if nd == None:
			print "node not found"
			return -1
	return

def PlotLineage(gplt, ltree, feature, node, withstr='lines', visit='all', replot=False, titlestr=None):
	parent = None
	data = {}
	if isinstance(node,type(ltree.root)):
		parent = node
	elif isinstance(node,type('c')):
		if ltree.leaf.get(node) != None:
			parent = ltree.leaf.get(node)
		else:	
			parent = ltree.lookup(ltree.root,node)
		if parent == None:
			print "node not found"
			return -1
	while parent.data != None:
		for tp in parent.data.time_points.keys():
			if parent.data.time_points[tp].get(feature) != None:
				if data.get(tp) != None:
					data[tp] += parent.data.time_points[tp].get(feature)
					#count[tp] += 1
				else:
					data[tp] = parent.data.time_points[tp].get(feature)
					#count[tp] = 1
		parent = parent.parent
	data = dict(normLinearData(data.items()))
	if len(data) > 0:
		xmin = min(data.keys())
		xmax = max(data.keys())
		gplt('set xrange[' + str(xmin) + ':' + str(xmax) + ']')
		gplt.xlabel('time (minutes)')
		#ylab = linewrap('mean ' + feature.replace('_',' '), 18)
		ylab = feature.replace('_',' ')
		gplt('set ylabel "' + ylab + '" font "Helvetica,10"')
		#gplt.ylabel('mean ' + feature.replace('_',' '))
		if replot:
			if withstr == '':
				gplt.replot(Gnuplot.Data(data.items(),inline=1, title=titlestr))
			else:
				gplt.replot(Gnuplot.Data(data.items(), with=withstr, inline=1, title=titlestr))			
		else:
			if withstr == '':
				gplt.plot(Gnuplot.Data(data.items(), inline=1, title=titlestr))
			else:
				gplt.plot(Gnuplot.Data(data.items(), with=withstr, inline=1, title=titlestr))			


def PlotAllLineages(gplt, ltree, feature, withstr='lines', visit='all', term='live', fdir=None, fname=None):
	gplt('set key top right')
	count = 0 
	for leaf in ltree.leaf.keys():
		if mod(count, 8) == 0:
			if term == 'live':
				gplt('set term ' + term)
			elif term == 'file':
				gplt('set term postscript enhanced color landscape font "Helvetica" 10')
				gplt('set output "' + path.joinpath(path(fdir), fname + str(count).rjust(10,'0') +'.ps').strip() + '"') 
			PlotLineage(gplt, ltree, feature, leaf, 'lines', 'all', False, leaf)
		else:
			PlotLineage(gplt, ltree, feature, leaf, 'lines', 'all', True, leaf)
		count += 1	

def PlotHist(bench, feature, emblist=None, withstr='', visit='all'):
	alldata = []
	data = {}
	dstdv = [] 
	dmean = {}
	if emblist == None:
		emblist = bench.embryo.keys()
	for emb in emblist:
		nodes = None 
		if visit == 'all':
			nodes = bench.embryo[emb].bfs("NotANode", bench.embryo[emb].root, bench.embryo[emb].findNode, True)	
		elif visit == 'one_child':
			nodes = bench.embryo[emb].bfs("NotANode", bench.embryo[emb].root, bench.embryo[emb].aChild, True)
		for nd in nodes:
			if nd != None:
				if nd.data != None:
					cdc = 0
					for tp in range(min(nd.data.time_points.keys()), min(min(nd.data.time_points.keys())+6, max(nd.data.time_points.keys())+1)):
						if nd.data.time_points[tp].get(feature) != None:
							if data.get(cdc) != None:
								data[cdc] += [nd.data.time_points[tp].get(feature)]
							else:
								data[cdc]=[]
								data[cdc].append(nd.data.time_points[tp].get(feature))
							#later on make this friendly with time_norm for multi-embryo analysis
							alldata += [tp, nd.data.time_points[tp].get(feature)]
						cdc +=1
	alldata = normLinearData(alldata)
	for cdc in data.keys():
		dmean[cdc] = sageobj(r.mean(data[cdc]))
		stdv = sqrt(sageobj(r.var(data[cdc])))	
		dstdv.append([cdc, dmean[cdc]-stdv])
		dstdv.append([cdc, dmean[cdc]+stdv])
		print "success"
	bench.gplt.xlabel(feature.replace('_',' '))
	bench.gplt('set ylabel "frequency" font "Helvetica,10"')
	xmin = 0	
	xmax = 5 
	bench.gplt('set xrange[' + str(xmin) + ':' + str(xmax) + ']')
	bench.gplt('set key top right')
	bench.gplt.plot(Gnuplot.Data(dmean.items(),with='points pt 3 lc rgb "cyan"',title="mean"), \
	Gnuplot.Data(dstdv,with='points pt 4 lc rgb "red"', title="one standard deviation"))


#def PlotLinealGroup(bench,

#for each emb, for each group, plot feature, PlotLineage

#now, for each cell in a group, foreach embryo, PlotLineage

def GenReport(bench):
	reportdir = 'report' + rm_symbols_datetime.sub('',datetime.datetime.now().isoformat())
	os.mkdir(path.joinpath(path(bench.CELLDIV_DIR), reportdir))
	bench.gplt('set term postscript enhanced color landscape font "Helvetica" 10')
	bench.gplt('set output "' + path.joinpath(path(bench.CELLDIV_DIR), reportdir,'000000000000000.ps').strip() + '"')
	bench.gplt('set multiplot layout 4,2 title "All Embryos"')
	PlotAllTP(bench, 'diameter', None, 'lines')
	PlotAllTP(bench, 'total_gfp', None, 'lines')
	PlotAllTP(bench, 'diameter_fold', None, 'lines')
	PlotAllTP(bench, 'gfp_fold', None, 'lines')
	PlotLRatio(bench, 2, None) 
	PlotAllTP(bench, 'sister-self_centroid_dist_from_mother', None, 'lines', 'one_child')
	PlotAllTP(bench, 'ratio_diam_sisterdiam', None, 'lines', 'one_child')
	PlotAllTP(bench, 'ratio_gfp_sistergfp', None, 'lines', 'one_child')
	bench.gplt('unset multiplot')
	for emb in bench.embryo.keys():
		bench.gplt('set term postscript enhanced color landscape font "Helvetica" 10')
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
	cwd = os.getcwd()
	os.chdir(bench.CELLDIV_DIR)
	commands.getoutput('/usr/bin/psjoin ' + reportdir + '/*.ps > ' + reportdir + '.ps') 
	commands.getoutput('rm -fr ' + reportdir)
	os.chdir(cwd)

def GenLineageReports(bench):
	reportdir = path.joinpath(path(bench.CELLDIV_DIR),  'LineageReports' + rm_symbols_datetime.sub('',datetime.datetime.now().isoformat())).strip()
	os.mkdir(path.joinpath(path(bench.CELLDIV_DIR), reportdir))
	features = ['diameter', 'total_gfp', 'diameter_fold', 'gfp_fold', 'sister-self_centroid_dist_from_mother', \
	'ratio_diam_sisterdiam', 'ratio_gfp_sistergfp']
	cwd = os.getcwd()
	os.chdir(reportdir)
	for feature in features:
		featuredir = path.joinpath(path(bench.CELLDIV_DIR), reportdir, feature)
		os.mkdir(featuredir)
		for emb in bench.embryo.keys():
			PlotAllLineages(bench.gplt, bench.embryo[emb], feature, term='file', fdir=featuredir, fname=emb+'_'+feature) 
		commands.getoutput('/usr/bin/psjoin ' + featuredir + '/*.ps > ' + path.joinpath(path(reportdir), feature + '.ps')) 
		#commands.getoutput('rm -fr ' + featuredir)
	os.chdir(cwd)
		
			
#need to find the first common ancestral cell division for which data exists.
#then, find the max tp amongst these and shift all others up to this tp.			
#Actually, add this as a "secondary feature" and save it as part of the embryo bench

def GenLineXEmbryo(bench):
	reportdir = path.joinpath(path(bench.CELLDIV_DIR),  'LineXEmbryo' + rm_symbols_datetime.sub('',datetime.datetime.now().isoformat())).strip()
	os.mkdir(path.joinpath(path(bench.CELLDIV_DIR), reportdir))
	features = ['diameter', 'total_gfp', 'diameter_fold', 'gfp_fold', 'sister-self_centroid_dist_from_mother', \
	'ratio_diam_sisterdiam', 'ratio_gfp_sistergfp']
	cwd = os.getcwd()
	os.chdir(reportdir)
	for feature in features:
		featuredir = path.joinpath(path(bench.CELLDIV_DIR), reportdir, feature)
		os.mkdir(featuredir)
		for emb in bench.embryo.keys():
			PlotAllLineages(bench.gplt, bench.embryo[emb], feature, term='file', fdir=featuredir, fname=emb+'_'+feature) 
		commands.getoutput('/usr/bin/psjoin ' + featuredir + '/*.ps > ' + path.joinpath(path(reportdir), feature + '.ps')) 
		#commands.getoutput('rm -fr ' + featuredir)
	os.chdir(cwd)







