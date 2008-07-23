#!/Applications/sage/sage 
# vim:set syntax=python:
load utils.sage
from zipfile import ZipFile

#time points are stored in <cell>_data as an array 
# of hashes, with the index specifying the time point
# and the key specifying the feature name 
class CellDiv:
	mother_name, daughter1_name, daughter2_name, \
	mother_data, daughter1_data, daughter2_data, \
	div_time \
	= '', '', '', [], [], [], -1 
	def __init__(self, mother_data):
		self.mother_data = mother_data


def CreateDivTree(nuclei_zip):
	DivisionTree = CBTree()
	NucFile = ZipFile(nuclei_zip,'r')
			
	return DivisionTree

	
