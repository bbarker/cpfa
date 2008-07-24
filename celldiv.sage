#!/Applications/sage/sage 
# vim:set syntax=python:
load utils.sage
from zipfile import ZipFile
#import re

#time points are stored in <cell>_data as an array 
# of hashes, with the index specifying the time point
# and the key specifying the feature name 
class CellDiv:
	mother_name, daughter1_name, daughter2_name, \
	div_time, time_points_m, time_points_d1, time_points_d2\
	= '', '', '', -1,  {}, {}, {}
	def __init__(self, mother_name):
		self.mother_name = mother_name

def CreateDivTree(nuclei_zip):
	DivisionTree = CBTree()
	#tp = re.compile('\d+')
	#Add initial cell names to the tree.
	root = DivisionTree.root = DivisionTree.addNode(None,None,'P')
	DivisionTree.addLeaf(None,'P',root)
	cur_node = DivisionTree.insertByParent(None,root,'P0')
	cur_node = DivisionTree.insertByParent(None,cur_node,'P1')
	cur_node = DivisionTree.insertByParent(None,cur_node.parent,'AB')
	cur_node = DivisionTree.insertByParent(None,cur_node,'ABa')
	cur_node = DivisionTree.insertByParent(None,cur_node.parent,'ABp')
	NucFile = ZipFile(nuclei_zip,'r')
	NucList = NucFile.namelist()
	prior_file = []
	next_file = cur_file = stratify(0,[fline.strip().split(',') for fline in NucFile.read(NucList[0]).rstrip().split('\n')],True)
	for i in range(0,len(NucList)):  	#time for a nasty parsing line - just to make things perlesque
		#cur_time = Integer(tp.findall(NucList[i])[0])
		cur_file = next_file
		if cur_file == []:
			break
		if i < len(NucList) - 1 and not NucFile.read(NucList[i+1]) == '':
			next_file = stratify(0,[fline.strip().split(',') for fline in NucFile.read(NucList[i+1]).rstrip().split('\n')],True) 
		else:
			next_file = []
		for l in cur_file:
			if Integer(l[1]) == 1 and not l[9].lower().startswith('polar'):
				cur_cd = CellDiv(l[9])
				tph = {}
				if l[3] > 0 and l[4] > 0:
					cur_cd.div_time = i+1 
					cur_cd.daughter1_name = next_file[l[3]-1][9]
					cur_cd.daughter2_name = next_file[l[3]-1][9]
				tph['x']=Integer(l[5])
				tph['y']=Integer(l[6])
				tph['z']=RealNumber(l[7])
				tph['diameter']=Integer(l[8])
				tph['total_gfp']=Integer(l[10])
				cur_cd.time_points_m[i+1]=tph
				#use leaf hash to look up parent nodes
		prior_file = cur_file	 		
	return DivisionTree

	
