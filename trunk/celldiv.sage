#!/Applications/sage/sage 
# vim:set syntax=python:
load utils.sage
import sys
from zipfile import ZipFile
#import re

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

class EmbryoBench:
	embryo, conf_file_path, conf_file, EMBRYO_DIR,\
	CELLDIV_DIR, BENCHMARK_LIST \
	= {}, './cpfa.conf', None, '', '', ''
	def __init__(self):
		for i in range(0, len(sys.argv)):
			if sys.argv[i] == "-c":
				conf_file_path = sys.argv[i+1]
			else:
				conf_file_path='./cpfa.conf'
		conf_file = open(conf_file_path,'r')
		line = map(lambda x: x.strip() , conf_file.readlines())
		for i in range(0, len(line)):
			if line[i].startswith('EMBRYO_DIR='):
				EMBRYO_DIR = line[i].replace('EMBRYO_DIR=','')
			elif line[i].startswith('CELLDIV_DIR='):
				CELLDIV_DIR = line[i].replace('CELLDIV_DIR=','')
			elif line[i].startswith('BENCHMARK_LIST='):
				BENCHMARK_LIST = line[i].replace('BENCHMARK_LIST=','')
					

def CreateDivTree(nuclei_zip):
	#create a module for utils??? - to allow for pickling
	DivisionTree = CBTree()
	#tp = re.compile('\d+')
	#Add initial cell names to the tree.
	root = DivisionTree.root = DivisionTree.addNode(None,None,'P')
	cur_node = DivisionTree.insertByParent(None,root,'P0')
	cur_node = DivisionTree.insertByParent(None,cur_node,'P1')
	cur_node = DivisionTree.insertByParent(None,cur_node.parent,'AB')
	cur_node = DivisionTree.insertByParent(None,cur_node,'ABa')
	cur_node = DivisionTree.insertByParent(None,cur_node.parent,'ABp')
	NucFile = ZipFile(nuclei_zip,'r')
	NucList = NucFile.namelist()
	prior_file = []
	next_file = cur_file = stratify(0,map(ValConvert,[fline.strip().split(',') for fline in NucFile.read(NucList[0]).rstrip().split('\n')]),True)
	for i in range(0,len(NucList)):  	#time for a nasty parsing line - just to make things perlesque
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
			if l[0] == 1 and not l[8].lower().startswith('polar'):
				new_cell = True
				cur_cd = CellDiv(l[8])
				#print cur_cd.time_points
				if l[1]-1 < 0:
					new_cell = True
					DivisionTree.leaf[l[8]].data = cur_cd
				elif prior_file[l[1]-1][8] == l[8]:
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
				cur_cd.time_points[i+1]=tph
				#print "cur_cd timepoints:"
				#print cur_cd.time_points
				#need to find node if it exists, could use a prior check or tree search  - then append any new data to node
				#print DivisionTree.printTree(root)
				if not new_cell or l[1]-1 < 0:		#This is not a new cell, append data to existing node
					#print "update:\nbefore:\n"
					#print  DivisionTree.leaf[l[8]].data.time_points
					DivisionTree.leaf[l[8]].data.time_points.update(cur_cd.time_points)
					#print "after:\n"
					#print  DivisionTree.leaf[l[8]].data.time_points
				else:					#We have a new cell, insert a node
					cur_node = DivisionTree.insertByParent(cur_cd,DivisionTree.leaf[prior_file[l[1]-1][8]],l[8])
					#print "new node:\n"
					#print  cur_node.data.time_points
				del cur_cd
		prior_file = cur_file
	#dt_tmp=open('dt_tmp.txt','w')
	#pickle.dump(DivisionTree,dt_tmp,2)
	#dt_tmp.close()
	return DivisionTree




	
