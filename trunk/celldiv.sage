#!/Applications/sage/sage 
# vim:set syntax=python:
load utils.sage
import sys
from zipfile import ZipFile
from bz2 import BZ2File
import Gnuplot
from path import path
#import re
import cPickle
Int = Integer #for shorthand purposes... 

#time points are stored in <cell>_data as an array 
# of hashes, with the index specifying the time point
# and the key specifying the feature name 
class CellDiv:
	mother_name, daughter1_name, daughter2_name, \
	div_time, time_points, \
	= '', '', '', -1,  {}
	def __init__(self, mother_name):
		self.mother_name = mother_name
		self.daughter1_name = ''
		self.daughter2_name = ''
		self.div_time=-1
		self.time_points = {}


def ValConvert(string_list):
	val_list=[]
	val_list += map(Int,string_list[0:7])
	val_list.append(RealNumber(string_list[7]))
	val_list.append(Int(string_list[8]))
	val_list.append(string_list[9].rstrip().lstrip())
	val_list.append(Int(string_list[10]))
	return val_list

#def BFT_Plot(gp, ltree, feature):
#	nodes = ltree.bfs("NotANode", ltree.root, ltree.findNode, True)
#	for nd in nodes:
#		PlotCDFeature(gp, ltree, nd, feature)
		
def CreateDivTree(nuclei_zip, last_tp=Infinity):
	#create a module for utils??? - to allow for pickling
	DivisionTree = CBTree()
	#tp = re.compile('\d+')
	#Add initial cell names to the tree.
	#store initial tree topology and names in config file later
	root = DivisionTree.root = DivisionTree.addNode(None,None,'P')
	p0 = cur_node = DivisionTree.insertByParent(None,root,'P0')
	p1 = cur_node = DivisionTree.insertByParent(None,cur_node,'P1')
	ab = cur_node = DivisionTree.insertByParent(None,cur_node.parent,'AB')
	aba = cur_node = DivisionTree.insertByParent(None,cur_node,'ABa')
	abp = cur_node = DivisionTree.insertByParent(None,cur_node.parent,'ABp')
	ems = cur_node = DivisionTree.insertByParent(None,p1,'EMS')
	p2 = cur_node = DivisionTree.insertByParent(None,p1,'P2')
	DivisionTree.leaf['P0']=p0
	DivisionTree.leaf['P1']=p1
	DivisionTree.leaf['AB']=ab
	DivisionTree.leaf['ABa']=aba
	DivisionTree.leaf['ABp']=abp
	DivisionTree.leaf['EMS']=ems
	DivisionTree.leaf['P2']=p2

	NucFile = ZipFile(nuclei_zip,'r')
	NucList = NucFile.namelist()
	prior_file = []
	next_file = cur_file = stratify(0,map(ValConvert,[fline.strip().split(',') for fline in NucFile.read(NucList[0]).rstrip().split('\n')]),True)
	last_tp = min(last_tp, len(NucList))
	#return DivisionTree
	for i in range(0,last_tp):  	#time for a nasty parsing line - just to make things perlesque
		#cur_time = Int(tp.findall(NucList[i])[0])
		cur_file = next_file
		if cur_file == []:
			break
		if i < len(NucList) - 1 and not NucFile.read(NucList[i+1]) == '':
			next_file = stratify(0,map(ValConvert,[fline.strip().split(',') for fline in NucFile.read(NucList[i+1]).rstrip().split('\n')]),True) 
		else:
			next_file = []
		for l in cur_file:
			#all indices of l drop by 2 in total due to stratify
			if l[0] == 1 and not (l[8].lower().startswith('polar') or l[8].lower().startswith('nuc')):
				new_cell = True
				cur_cd = CellDiv(l[8])
				#print cur_cd.time_points
				if l[1]-1 < 0: #in the initial tree, so append data
					new_cell = True
					DivisionTree.leaf[l[8]].data = cur_cd
				elif prior_file[l[1]-1][8] != l[8]: #new cell and new node,
					new_cell = True					#no need to append data
				else:
					new_cell = False
				tph = {}
				if l[2] > 0 and l[3] > 0:
					cur_cd.div_time = i+1 
					cur_cd.daughter1_name = next_file[l[2]-1][8]
					cur_cd.daughter2_name = next_file[l[3]-1][8]
					if not new_cell or l[1]-1 < 0:
						DivisionTree.leaf[l[8]].data.daughter1_name = cur_cd.daughter1_name
						DivisionTree.leaf[l[8]].data.daughter2_name = cur_cd.daughter2_name
						DivisionTree.leaf[l[8]].data.div_time = cur_cd.div_time
						#handle key error exceptions by doing a (bfs?) search
				tph['x']=l[4]
				tph['y']=l[5]
				tph['z']=l[6]
				tph['diameter']=l[7]
				tph['total_gfp']=l[9]
				#these are secondary features that are easiest to calculate in the first pass:
				dist_vec = []
				for ll in cur_file:
					if l[8] != ll[8]:
						dist_vec.append(RR(distance((tph['x'],tph['y'],tph['z']),(ll[4],ll[5],ll[6]))))
				tph['L_min']=min(dist_vec)
				l_dist = RR(-1)
				if not l[1]-1 < 0:
					l_dist = RR(distance((prior_file[l[1]-1][4],prior_file[l[1]-1][5],prior_file[l[1]-1][6]),(l[4],l[5],l[6])))	
				tph['l']=l_dist
				tph['l/(L_min/2)']= RR(tph['l']/(tph['L_min']/2))
				cur_cd.time_points[i+1]=tph
				#need to find node if it exists, could use a prior check or tree search  - then append any new data to node
				if not new_cell or l[1]-1 < 0:		#This is not a new node, append data to existing node
					DivisionTree.leaf[l[8]].data.time_points.update(cur_cd.time_points)
				else:					#We have a new cell, insert a node
					cur_node = DivisionTree.insertByParent(cur_cd,DivisionTree.leaf[prior_file[l[1]-1][8]],l[8])
		prior_file = cur_file
	#cleanup
	#del DivisionTree.leaf['P']
	#del DivisionTree.leaf['P0']
	#del DivisionTree.leaf['P1']
	#del DivisionTree.leaf['AB']
	#del DivisionTree.leaf['ABa']
	#del DivisionTree.leaf['ABp']
	return DivisionTree



class EmbryoBench:
	embryo, conf_file_path, conf_file, EMBRYO_DIR,\
	CELLDIV_DIR, BENCHMARK_LIST, end_time, nuclei_files, gp \
	= {}, './cpfa.conf', None, '', '', '', {}, [], None
	def __init__(self):
		self.gp = Gnuplot.Gnuplot(debug=1)
		self.conf_file_path='./cpfa.conf'
		reload = '' 
		for i in range(0, len(sys.argv)):
			if sys.argv[i] == "-c" or sys.argv[i] == "-config":
				self.conf_file_path = sys.argv[i+1]
			elif sys.argv[i] == "-r" or sys.argv[i] == "-reload":
				reload = sys.argv[i+1]
		reload_list=[]
		if reload != '' and reload != 'all':
			reload_list=list(set(reload.strip().split(',')))
		self.conf_file = open(self.conf_file_path,'r')
		line = map(lambda x: x.strip() , self.conf_file.readlines())
		for i in range(0, len(line)):
			if line[i].startswith('EMBRYO_DIR='):
				self.EMBRYO_DIR = line[i].replace('EMBRYO_DIR=','')
			elif line[i].startswith('CELLDIV_DIR='):
				self.CELLDIV_DIR = line[i].replace('CELLDIV_DIR=','')
			elif line[i].startswith('BENCHMARK_LIST='):
				self.BENCHMARK_LIST = line[i].replace('BENCHMARK_LIST=','')
			elif line[i].startswith('EMBRYOS_TO_LOAD='):
				self.EMBRYOS_TO_LOAD = line[i].replace('EMBRYOS_TO_LOAD=','')
		bmlist = open(self.BENCHMARK_LIST,'r')
		line = map(lambda x: x.split() , bmlist.readlines())
		line.pop(0)
		bmlist.close()
		for l in line:
			self.end_time[l[0]] = Integer(l[2])
		#load each nuclei file.  later, get it to attempt loading a tree if the write time on the tree file is newer
		#than the nuclei file
		potential_directories = []
		line = self.EMBRYO_DIR.split(',') 
		for l in line:
			if path(l).isdir():
				potential_directories += map(lambda x: x.basename(), path(l).dirs())
		print "potential directories:"
		print potential_directories

		trees = []
		for bl in self.end_time.keys():
			tfile = path.joinpath(path(self.CELLDIV_DIR), bl + '.divtree.bz2')
			if tfile.isfile():
				trees += [bl]
		print "tree files:"
		print trees
		nuclei = list(set(self.end_time.keys()).intersection(potential_directories+trees))
		if self.EMBRYOS_TO_LOAD.strip().lower() != 'all':
			nuclei = list(set(nuclei).intersection(self.EMBRYOS_TO_LOAD.split(',')))
		print "embryos to load:"
		print nuclei
		#only reload nuclei that are specified or new embryos
		new_embryos = []
		newest = {}
		for nuc in nuclei:
			mtime_nuc = {}
			p = path.joinpath(path(self.EMBRYO_DIR), nuc, 'annot/dats')
			if p.isdir():
				nfiles = p.files('*' + nuc + '*zip*')
				for nf in nfiles:
					mtime_nuc[nf.mtime]=nf.strip()
				newest[nuc]=mtime_nuc[max(mtime_nuc.keys())]
		def unpickle_tree():
			print tfile.strip() + " is being loaded from compressed tree.\n"
			treefile = BZ2File(tfile,'r')
			self.embryo[nuc]=cPickle.load(treefile)
			treefile.close()		
		for nuc in nuclei:
			tfile = path.joinpath(path(self.CELLDIV_DIR), nuc + '.divtree.bz2')
			if tfile.isfile():
				print "tfile is a file!\n"
				if newest.get(nuc) != None:
					if path(newest[nuc]).mtime > tfile.mtime:
						new_embryos += [nuc]	
					else:
						unpickle_tree()
				else:
					unpickle_tree()
			else:
				new_embryos += [nuc]
		if reload == 'all':
			reload_list=nuclei
		else:
			reload_list=list(set(nuclei).intersection(reload_list+new_embryos))
		for nuc in reload_list:
			mtime_nuc = {}
			p = path.joinpath(path(self.EMBRYO_DIR), nuc, 'annot/dats')
			if p.isdir():
				print newest[nuc] + " is being loaded from the nuclei file.\n"
				self.embryo[nuc] = CreateDivTree(newest[nuc], self.end_time[nuc])	
				self.embryo[nuc].genExtraFeatures()
		for nuc in self.embryo.keys():
			treepath = path.joinpath(path(self.CELLDIV_DIR), nuc + ".divtree.bz2")
			treefile = BZ2File(treepath.strip(),'w')
			cPickle.dump(self.embryo[nuc], treefile)
			treefile.close()
