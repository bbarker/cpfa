#!/Applications/sag/sage 
# vim:set syntax=python:

import sys
import subprocess
from sage.all import *
import pprint




class CNode:
	parent, left, right, key, data = None, None, None, None, 0 
    
	def __init__(self, data, parent, key):
        # initializes the data members
		self.parent = parent 
		self.left = None
		self.right = None
		self.data = data
		self.key = key

class CBTree:
	def __init__(self):
		# initializes the root member
		self.root = None
		self.leaf = {}

	def addLeaf(self, parent, key, newnode):
		if parent != None and self.leaf.get(parent) != None:
			del self.leaf[parent]
		self.leaf[key] = newnode
		
 
	def addNode(self, data, parent, key):
		# creates a new node and returns it
		return CNode(data, parent, key)

	def printNode(self, target, node):
		print node.data
		return None

	def findNode(self, target, node):
		if node.key == target:
			return node
		else:
			return None

	def bfs(self, target, top_node, visit):
		"""Breadth-first search on a graph, starting at top_node."""
		queue = [top_node]
		while len(queue):
			new_nodes_at = len(queue)-1
			curr_node = queue.pop(0)    # Dequeue
			if visit(target, curr_node) != None:
				return visit(target, curr_node)
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
		return None

	def printTree(self, root):
		self.bfs("NotANode", root, self.printNode)

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
		self.addLeaf(parent.data, key, new_node)
		return new_node


#do a binary tree search, if that fails, fall back to breadth-first traversal (for non systematic names)
	def lookup(self, root, target):
		# looks for a value into the tree
		if root == None:
			return bfs(target, root, self.findNode)
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
					return self.bfs(target, root_top, self.findNode)


 
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

