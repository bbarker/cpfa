#!/Applications/sage/sage 
# vim:set syntax=python:

import sys
import subprocess
from sage.all import *
import pprint
import re
#pp = pprint.PrettyPrinter(indent=4)

##global rexexes##
#typestr = re.compile('\'\S\'')
rm_symbols_datetime = re.compile('[\-\:\.\,]')

def get_closing_idx(dir, start, dleft, dright, text):
	tupr = ()
	stack=0
	if dir < 0:
		tupr = (start,-1,-1)
	else:
		tupr = (start,len(text),1)
	for i in range(tupr[0],tupr[1],tupr[2]):
		if text[i] == dleft:
			stack += 1
		elif text[i] == dright:
			stack -= 1
		if stack == 0:
			return i
		
#this will eventually be added to the newick library
def del_newick_nodes(rmnode,tree):
	tree=tree.strip()
	pstack=[]
	for nd in rmnode:
		nd_idx = tree.find(nd)-1
		if nd_idx > 0:
			if tree[nd_idx+len(nd)+2]==')' and tree[nd_idx-1]!=',': # Do left traversal
				break		
			elif tree[nd_idx+len(nd)+2]=='(' and tree[nd_idx-1]=='(': # Do right traversal
				break
			elif tree[nd_idx-1]==',': #del left comma + node
				break
			else: #del node + right comma
				break
	
		
	

def distance(p1,p2):
	diff_tup = tuple((vector(p1)-vector(p2)))
	return sqrt(sum(map(lambda x: x^2, diff_tup)))

#returns a stratified list (or hash - if items in LoL[i][col] aren't all int)
#of lists indexed by the items in LoL[i][col] (i in [0,len(LoL)]
#convert will attempt to justify indices to 0 and use an array instead of a dict
def stratify(col, LoL, convert=False):
	newlist=[]
	col_items=[]
	col_min=None
	if convert:
		for i in range(0,len(LoL)):
			LoL[i][col]=Integer(LoL[i][col])
			col_items.append(LoL[i][col])
	col_min=min(col_items)
	if col_min != 0:
			for i in range(0,len(LoL)):
				LoL[i][col]=LoL[i][col]-col_min
			col_items = [l[col] for l in LoL]
			col_min = 0
	else:
		col_items = [l[col] for l in LoL]
	if len(set(col_items)) != len(col_items):
		raise KeyError()
	else:
		tl = [type(c) for c in col_items]
		if len(set(tl)) == 1 and type(col_items[0]) == type(1) and max(col_items)-col_min+1 == len(LoL):
			newlist = [None for l in col_items]
			for l in LoL:
				newlist[l.pop(col)]=l 
		else:
			newlist = {} 
			for l in LoL:
				newlist[l.pop(col)]=l 
	return newlist



def getTypeStr(val):
	return repr(type(val)).replace('<type \'','').replace('\'>','')
	
class CNode:
	parent, left, right, key, data = None, None, None, None, 0 
    
	def __init__(self, data, parent, key):
        # initializes the data members
		self.parent = parent 
		self.left = None
		self.right = None
		self.data = data
		self.key = key


#Assumes Sulston-style naming conventions for anterior,posterior,
#left,right,dorsal and ventral, although as long as the 
#parent-child relationships are specified this class will work
#regardless (and in fact, they must be specified).
class CBTree:
	def __init__(self):
		# initializes the root member
		self.root = None
		self.leaf = {}

#for the sake of interoperability with other software,
#this will actually only remove a leaf node if it has 
#2 children, which works fine since we eventually have 
#a full binary tree.  Consider changing the name.
	def addLeaf(self, parent, key, newnode):
		if parent != None and self.leaf.get(parent) != None:
			right_empty = left_empty = True
			if self.leaf[parent].left != None:
				if self.leaf[parent].left.key != None:
					left_empty = False
			if self.leaf[parent].right != None:
				if self.leaf[parent].right.key != None:
					right_empty = False
			if not right_empty and not left_empty:
				del self.leaf[parent]
		self.leaf[key] = newnode
		
 
	def addNode(self, data, parent, key):
		# creates a new node and returns it
		return CNode(data, parent, key)

	def printNode(self, target, node):
		print node.key
		return None

	def secondaryFeature(self, target, node):
		#First calculate features that require only the current node.
		if node != None:
			if node.data != None:
				tps = node.data.time_points.keys()
				tps.sort()
				node.data.time_points[tps[0]]['diameter_fold'] = 1.0
				node.data.time_points[tps[0]]['gfp_fold'] = 1.0
				tps.pop(0)
				for tp in tps: 
					node.data.time_points[tp]['diameter_fold'] =  RR(\
					node.data.time_points[tp]['diameter'] /          \
					node.data.time_points[tp-1]['diameter'])
					if node.data.time_points[tp-1]['total_gfp'] == 0:
						print node.key + "has 0 gfp at time " + str(tp-1) + "\n"
						node.data.time_points[tp]['gfp_fold'] = RR(-1)  
					else:
						node.data.time_points[tp]['gfp_fold'] =  RR(  \
						node.data.time_points[tp]['total_gfp'] /      \
						node.data.time_points[tp-1]['total_gfp'])
		#Now calculate features that only require current node and parent.
		#Perhaps somewhat confusingly, the current node 
		#if node.parent != None and node != None
		#	if node.parent.data != None and node.data != None
		#Now calculate features that require the current node as well as
		#it's sister and parent.
		if node.left != None and node.right != None and node != None:
			if node.left.data != None and node.right.data != None and node.data != None:
				tps = list(set.intersection(set(node.left.data.time_points.keys()) \
				, set(node.right.data.time_points.keys())))
				tps.sort()
				max_p_tp = max(node.data.time_points.keys())
				for tp in tps:
					node.left.data.time_points[tp]['ratio_diam_sisterdiam'] = RR(\
					node.left.data.time_points[tp]['diameter']/node.right.data.time_points[tp]['diameter'])
					node.right.data.time_points[tp]['ratio_diam_sisterdiam'] = 1.0/ \
					node.left.data.time_points[tp]['ratio_diam_sisterdiam']
					
					if (node.right.data.time_points[tp]['total_gfp'] == 0 or \
					node.left.data.time_points[tp]['total_gfp'] == 0):
						print node.key + " has children with 0 gfp at time " + str(tp) + "\n"
						node.left.data.time_points[tp]['ratio_gfp_sistergfp'] = \
						node.right.data.time_points[tp]['ratio_gfp_sistergfp'] = RR(-1)
					else:
						node.left.data.time_points[tp]['ratio_gfp_sistergfp'] = RR(\
						node.left.data.time_points[tp]['total_gfp']/node.right.data.time_points[tp]['total_gfp'])
						node.right.data.time_points[tp]['ratio_gfp_sistergfp'] = 1.0/ \
						node.left.data.time_points[tp]['ratio_gfp_sistergfp']
					cx = RR(node.left.data.time_points[tp]['x'] + node.right.data.time_points[tp]['x'])/2
					cy = RR(node.left.data.time_points[tp]['y'] + node.right.data.time_points[tp]['y'])/2
					cz = RR(node.left.data.time_points[tp]['z'] + node.right.data.time_points[tp]['z'])/2	
					node.left.data.time_points[tp]['sister-self_centroid_dist_from_mother'] =  \
					node.right.data.time_points[tp]['sister-self_centroid_dist_from_mother'] = \
					distance(map(RR,(node.data.time_points[max_p_tp]['x'], node.data.time_points[max_p_tp]['y'], \
					node.data.time_points[max_p_tp]['z'])), (cx,cy,cz))
				
	def printCellDiv(self, output, node):
		if node.data == None:
			return None
		#get header in string (mother, d1, d2 names)
		output.write('###\t' + node.data.mother_name + '\t' + node.data.daughter1_name \
		+ '\t' + node.data.daughter2_name + '\t' + str(node.data.div_time) + '\n')
		#get mother data in string	
		astring=''
		output.write("Mother: " + node.data.mother_name + "\n")
		tps = node.data.time_points.keys()
		tps.sort()	
		for tp in tps:
			output.write(astring.join(map(lambda x: str(x) + '\t', [tp] + node.data.time_points[tp].values()) + ['\n']))
		#get d1 data
		output.write("Daughter 1: " + node.data.daughter1_name + "\n")
		if node.left != None:
			if node.left.data != None:
				tps = node.left.data.time_points.keys()
				tps.sort()
				for tp in tps:
					output.write(astring.join(map(lambda x: str(x) + '\t', [tp] + node.left.data.time_points[tp].values()) + ['\n']))
		#get d2 data
		output.write("Daughter 2: " + node.data.daughter2_name + "\n")
		if node.right != None:
			if node.right.data != None:
				tps = node.right.data.time_points.keys()
				tps.sort()
				for tp in tps:
					output.write(astring.join(map(lambda x: str(x) + '\t', [tp] + node.right.data.time_points[tp].values()) + ['\n']))

		
	def findNode(self, target, node):
		if node.key == target:
			return node
		else:
			return None


	def aChild(self, target, node):
		"""Used as a visit (traversal) function for bfs.  It only returns data for exactly
		   one child of every node.  This is used when we want to look at, say, the distribution
			of sister-sister feature ratios."""
		nl = False
		nr = False
		if node.left != None:
			if node.left.data != None:
				nl = True
		if node.right != None:
			if node.right.data != None:
				nr = True
		if nr:
			return node.right
		elif nl:
			return node.left


	def bfs(self, target, top_node, visit, traverse=False):
		"""Breadth-first search on a graph, starting at top_node."""
		queue = [top_node]
		while len(queue):
			new_nodes_at = len(queue)-1
			curr_node = queue.pop(0)    # This should be more logical.. 
			if not traverse and visit(target, curr_node) != None:
				print dir(visit(target, curr_node))
				if search(dir(visit(target, curr_node)),'key')[0]:
					if visit(target, curr_node).key == target:
						yield visit(target, curr_node)
						return	
			elif traverse:
				if visit(target, curr_node) != None:
					yield  visit(target, curr_node)
				else:
					yield curr_node
			qlen=len(queue)
			if (curr_node.left != None):
				queue.extend([curr_node.left])
			if (curr_node.right != None):
				queue.extend([curr_node.right])
			for i in range(new_nodes_at, qlen):
				if (queue[i].left != None):
					queue.extend([queue[i].left])
				if (queue[i].right != None):
					queue.extend([queue[i].right])
		return

	def printTree(self, root):
		self.bfs("NotANode", root, self.printNode).next()
	
	def genExtraFeatures(self):
		nodes = self.bfs("NotANode", self.root, self.secondaryFeature)
		for nd in nodes:
			nd.next()

	def printLineage(self, output_file):
		output=open(output_file,'w')
		#print column headings (types and names)
		types = [getTypeStr(1)] + map(getTypeStr,self.leaf.values()[0].data.time_points.values()[0].values())
		names = ['time'] + self.leaf.values()[0].data.time_points.values()[0].keys()
		for i in range (0, len(types)):
			output.write(names[i] + "\t")
		output.write("\n")	
		for i in range (0, len(types)):
			output.write(types[i] + "\t")
		output.write("\n")	
		self.bfs(output, self.root, self.printCellDiv)
			

	def insertByParent(self, data, parent, key):
		new_node = self.addNode(data, parent, key)
		loc = key.replace(parent.key,'',1)
		if len(loc):
			loc=loc[0]
		if parent.left != None:
			if parent.left.key == new_node.key:
				parent.left.data = new_node.data
				return new_node		
		if parent.right != None:
			if parent.right.key == new_node.key:
				parent.right.data = new_node.data
				return new_node
		if loc == 'l' or loc == 'd' or loc == 'a':
			parent.left = new_node
		elif loc == 'r' or loc == 'v' or loc == 'p':
			parent.right = new_node 
		elif parent.left == None:
			parent.left = new_node
		else:
			parent.right = new_node
		self.addLeaf(parent.key, key, new_node)
		return new_node


#do a binary tree search, if that fails, fall back to breadth-first traversal (for non systematic names)
	def lookup(self,root, target):
		# looks for a value into the tree
		if root == None:
			return self.bfs(target, root, self.findNode).next()
		else:
			# if it has found it...
			if target == root.key:
				return root
			else:
				if target.startswith(root.key):
					if loc == 'l' or loc == 'd' or loc == 'a':
						return self.lookup(root.left, target)
					elif loc == 'r' or loc == 'v' or loc == 'p':
						return self.lookup(root.right, target)
				else:
					return self.bfs(target, self.root, self.findNode).next()

	def getDepth(self, target):
		node = target
		if type(target) == type('a'):
			node = self.lookup(self.root, target)
		count = 0
		while node != self.root:
			count += 1
			node = node.parent 	
		return count

	#def traverseToRoot(self, visit, nd):
		

 
#	def minValue(self, root):
#		# goes down into the left
#		# arm and returns the last value
#		while(root.left != None):
#			root = root.left
#		return root.data

#	def maxDepth(self, root):
#		if root == None:
#			return 0
#		else:
#			# computes the two depths
#			ldepth = self.maxDepth(root.left)
#			rdepth = self.maxDepth(root.right)
#			# returns the appropriate depth
#			return max(ldepth, rdepth) + 1
            
#	def size(self, root):
#		if root == None:
#			return 0
#		else:
#			return self.size(root.left) + 1 + self.size(root.right)

#	def printRevTree(self, root):
#		# prints the tree path in reverse
#		# order
#		if root == None:
#			pass
#		else:
#			self.printRevTree(root.right)
#			print root.data,
#			self.printRevTree(root.left)


#if __name__ == "__main__":
#	# create the binary tree
#	BTree = CBTree()
#	# add the root node
#	root_top = root = BTree.root = BTree.addNode('P',None,'P')
#	BTree.addLeaf(None, 'P', root)
#	# ask the user to insert values
#	mystr = "ABCDE"
#	root = BTree.insertByParent('A',root, 'A') 
#	for i in range(0, 4):
#		# insert values
#		root = BTree.insertByParent(mystr[i+1], root, mystr[i+1])
#	print BTree.printTree(root_top)
#	print BTree.printRevTree(root_top)
#	data = raw_input("insert a value to find: ")
#	if BTree.lookup(root_top, data) != None:
#		print "found" 
#	else:   
#		print "not found"
#        
#	print BTree.minValue(root_top)
#	print BTree.maxDepth(root_top)
#	print BTree.size(root_top)

