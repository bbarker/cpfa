#!/Applications/sage/sage 
# vim:set syntax=python:

import sys
import subprocess
from sage.all import *
#from rpy import * 
import pprint


# A binary ordered tree example

class CNode:
	parent, left, right, data = None, None, None, 0 
    
	def __init__(self, data, parent):
        # initializes the data members
		self.parent = parent 
		self.left = None
		self.right = None
		self.data = data

class CBTree:
	def __init__(self):
		# initializes the root member
		self.root = None
		self.leaf = {}

	def addLeaf(self, parent, data, newnode):
		print "1:"
		print self.leaf
		if parent != None:
			del self.leaf[parent]
		self.leaf[data] = newnode
		print "2:" 
		print self.leaf
 
	def addNode(self, data, parent):
		# creates a new node and returns it
		return CNode(data, parent)

	def visit(self, target, node):
		if node.data == target:
			return node
		else:
			return None

	def bfs(self, target, top_node, visit):
		"""Breadth-first search on a graph, starting at top_node."""
		#visited = set()
		queue = [top_node]
		while len(queue):
			new_nodes_at = len(queue)-1
			curr_node = queue.pop(0)    # Dequeue
			print 'curr_node.data: ' + curr_node.data + '\n'
			#print 'curr_node.parent.data: ' + curr_node.parent.data + '\n'
			#print 'curr_node.right.data: ' + curr_node.right.data + '\n'
			#print 'curr_node.left.data: ' + curr_node.left.data + '\n'
			if visit(target, curr_node) != None:
				return visit(target, curr_node)
			#visited.add(curr_node)
			# Enqueue non-visited and non-enqueued children
			qlen=len(queue)
			for i in range(new_nodes_at, qlen):
				if (queue[i].left != None):
					queue.extend([queue[i].left])
				if (queue[i].right != None):
					queue.extend([queue[i].right])
			#queue.extend(c for c in curr_node.children if c not in visited and c not in queue)
		return None

	#change the insertion method to insert by parent name, left node first
	def insert(self, root, data, parent):
		# inserts a new data
		if root == None:
			# it there isn't any data
			# adds it and returns
			new_node = self.addNode(data, None)
			self.addLeaf(parent.data, data, new_node)
			return new_node
	# enters into the tree
		#if parent.startswith(root.data):
		print 'parent.data: ' + parent.data + '\n'
		print 'root.data: ' + root.data + '\n' 
		print 'data: ' + data + '\n'
		print 'root_top.data: ' + root_top.data + '\n'
		#loc = data.partition(root.data)[2][0]
		loc = data.replace(root.data,'',1)
		if loc == 'l' or loc == 'd' or loc == 'a':
			root.left = self.insert(root.left, data, parent)
			return root.left
		elif loc == 'r' or loc == 'v' or loc == 'p':
			# processes the right-sub-tree
			root.right = self.insert(root.right, data, parent)
			return root.right
		else:
			loc = ''
			pnode = self.bfs(parent, root_top, self.visit)
			if pnode != None:
				loc = data.replace(pnode.data,'',1)
			if loc == 'l' or loc == 'd' or loc == 'a':
				root.left = self.insert(root.left, data, parent)
				return root.left
			elif loc == 'r' or loc == 'v' or loc == 'p':
				root.right = self.insert(root.right, data, parent)
				return root.right
			elif root.left == None:
				root.left = self.insert(root.left, data, parent)
				return root.left
			else:
				root.right = self.insert(root.right, data, parent)
				return root.right

       

#do a binary tree search, if that fails, fall back to breadth-first traversal (for non systematic names)
	def lookup(self, root, target):
		# looks for a value into the tree
		if root == None:
			return bfs(target, root, self.visit)
		else:
			print root.data
			# if it has found it...
			if target == root.data:
				return root
			else:
				if target.startswith(root.data):
					if loc == 'l' or loc == 'd' or loc == 'a':
						return self.lookup(root.left, target)
					elif loc == 'r' or loc == 'v' or loc == 'p':
						return self.lookup(root.right, target)
					else:
						return bfs(target, root, self.visit)


 
	def minValue(self, root):
		# goes down into the left
		# arm and returns the last value
		while(root.left != None):
			root = root.left
		return root.data

	def maxDepth(self, root):
		if root == None:
			return 0
		else:
			# computes the two depths
			ldepth = self.maxDepth(root.left)
			rdepth = self.maxDepth(root.right)
			# returns the appropriate depth
			return max(ldepth, rdepth) + 1
            
	def size(self, root):
		if root == None:
			return 0
		else:
			return self.size(root.left) + 1 + self.size(root.right)

	def printTree(self, root):
		# prints the tree path
		if root == None:
			pass
		else:
			self.printTree(root.left)
			print root.data,
			self.printTree(root.right)

	def printRevTree(self, root):
		# prints the tree path in reverse
		# order
		if root == None:
			pass
		else:
			self.printRevTree(root.right)
			print root.data,
			self.printRevTree(root.left)


if __name__ == "__main__":
	# create the binary tree
	BTree = CBTree()
	# add the root node
	root_top = root = BTree.root = BTree.addNode('P',None)
	BTree.addLeaf(None, 'P', root)
	# ask the user to insert values
	mystr = "ABCDE"
	root = BTree.insert(root,'A',root) 
	print "new root: " + root.data + "\n"
	for i in range(0, 4):
		# insert values
		print BTree.printTree(root_top)
		root = BTree.insert(root_top, mystr[i+1], root)
		print "new root: " + root.data + "\n"
	print BTree.printTree(root_top)
	print BTree.printRevTree(root_top)
	data = raw_input("insert a value to find: ")
	if BTree.lookup(root_top, data) != None:
		print "found" 
	else:   
		print "not found"
        
	print BTree.minValue(root_top)
	print BTree.maxDepth(root_top)
	print BTree.size(root_top)

