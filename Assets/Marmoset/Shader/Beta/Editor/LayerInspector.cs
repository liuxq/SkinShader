// Copyright (c) 2014 Marmoset LLC
//
using UnityEngine;
using UnityEditor;

using System;
using System.IO;
using System.Xml;
using System.Text;
using System.Collections; 
using System.Collections.Generic;
using System.Linq;

public class LayerInspector : MaterialEditor {


	// draws a standard material property, optionally disabled, and either compact or full-sized. 
	// minimal flag on texture properties means hide UV tiling.
	private void DrawProperty(MaterialProperty prop, string label, string subLabel, bool disabled) {
		EditorGUI.BeginDisabledGroup(disabled);
		if( prop.type == MaterialProperty.PropType.Color ) {
			EditorGUIUtility.labelWidth = 134;
			EditorGUIUtility.fieldWidth = 84;
		}
		else if( prop.type == MaterialProperty.PropType.Texture ) {
			EditorGUIUtility.labelWidth = 220;
			EditorGUIUtility.fieldWidth = 84;
		}
		else {
			EditorGUIUtility.labelWidth = 134;
			EditorGUIUtility.fieldWidth = 84;
		}

		if( prop.type == MaterialProperty.PropType.Color ) {
			ShaderProperty(prop, label);
		}
		else if( prop.type == MaterialProperty.PropType.Texture ) {
			TextureProperty(prop, label);
			/*if( subLabel.Length > 0 ) {
				Rect r = GUILayoutUtility.GetLastRect();
				r.x = EditorGUIUtility.labelWidth - 21f;
				EditorGUI.BeginDisabledGroup(true);
				EditorGUI.LabelField(r, subLabel);
				EditorGUI.EndDisabledGroup();
			}*/
			GUILayout.Space(6);
		} else {
			ShaderProperty(prop, label);
		}
		EditorGUI.EndDisabledGroup();
	}

	//Draws a property that's also a section header (usually a checkbox) along with a collapse/expand triangle. Returns true if block is expanded.
	public void DrawPropertyHeader(PropertyBlock block, MaterialProperty prop, string label) {
		float controlSize = 110;
		EditorGUIUtility.fieldWidth = controlSize;
		EditorGUIUtility.labelWidth = 0;
		
		EditorGUILayout.BeginHorizontal();
		
		//draw folding triangle and retrieve state
		Rect r = EditorGUILayout.GetControlRect(GUILayout.Width(0), GUILayout.Height(16));
		block.open = EditorGUI.Foldout(r, block.open, "", false);

		if( !block.label ) {
			//draw a 10-pixel checkbox or a control-sized whatever-else (combo box usually)
			r = EditorGUILayout.GetControlRect(GUILayout.Width(block.checkbox ? 10 : controlSize), GUILayout.Height(16));			
			//draw property with label to the right
			ShaderProperty(r, prop, "");
		}
		EditorGUILayout.LabelField(label);
		
		EditorGUILayout.EndHorizontal();
	}

	//structure defining the header of a block of material properties. The header can be enabled/disabled by a series of keywords or
	//collapsed/expanded with a GUI foldout.
	public class PropertyBlock {
		public bool open = true; 		//current folded state, collapsed or expanded
		public bool enabled = true;   	//current state of keywords enabling/disabling this block of properties
		public bool checkbox = false;	//if true, this property header is drawn as a checkbox left of the label, otherwise it is drawn as a combo box
		public bool label = false;		//if true, no property gui is drawn for this element, it is just a section label
		public string[] keywords = null;	//list of keywords that will toggle this block as enabled and visible

		public PropertyBlock(string[] keys, bool isCheckbox) {
			this.keywords = keys;
			this.checkbox = isCheckbox;
		}

		public void evalKeywords( string[] matKeywords ) {
			this.enabled = false;
			if( this.keywords == null ) {
				enabled = true;
			} else {
				for(int i=0; i<this.keywords.Length && !this.enabled; ++i) {
					this.enabled |= matKeywords.Contains(this.keywords[i]);
				}
			}
		}
	};

	private Dictionary<string, PropertyBlock> blocks = null;
	public LayerInspector() {
		blocks = new Dictionary<string, PropertyBlock>();
		blocks.Add( "Header_Layering",  new PropertyBlock(null, true ) );	blocks["Header_Layering"].label = true;
		//blocks.Add( "Marmo_Diffuse",    new PropertyBlock(null, true ) );	blocks["Marmo_Diffuse"].label = true;
		//blocks.Add( "Marmo_Specular",	new PropertyBlock(new string[]{	"MARMO_SPECULAR_ON" },	true) );
		//blocks.Add( "Marmo_Bump",		new PropertyBlock(new string[]{	"MARMO_BUMP_ON", "MARMO_BUMP_ON" },		true) );
		blocks.Add( "Header_Shared",  new PropertyBlock(null, true ) ); 	blocks["Header_Shared"].label = true;
		blocks.Add( "Header_Layer0",  new PropertyBlock(null, true ) ); 	blocks["Header_Layer0"].label = true;
		blocks.Add( "Header_Layer1",  new PropertyBlock(null, true ) ); 	blocks["Header_Layer1"].label = true;
		blocks.Add( "Header_Layer2",  new PropertyBlock(null, true ) ); 	blocks["Header_Layer2"].label = true;
		blocks.Add( "Header_Layer3",  new PropertyBlock(null, true ) ); 	blocks["Header_Layer3"].label = true;

		blocks.Add( "Header_Advanced",  new PropertyBlock(null, true ) ); 	blocks["Header_Advanced"].label = true;
	}


	public override void OnInspectorGUI() {


		Material targetMat = target as Material;
		string[] keyWords = targetMat.shaderKeywords;

		foreach( KeyValuePair<string, PropertyBlock> itr in blocks ) {
			itr.Value.evalKeywords(keyWords);
		}
		
		//material checkboxes
		bool twoLayerOn =  keyWords.Contains("MARMO_LAYER_COUNT_2_LAYER");
		bool fourLayerOn = keyWords.Contains("MARMO_LAYER_COUNT_4_LAYER");
		bool specOn = keyWords.Contains("MARMO_SPECULAR_ON");
		bool diffSpecOn = keyWords.Contains("MARMO_DIFFUSE_SPECULAR_COMBINED_ON");
		bool bumpOn = keyWords.Contains("MARMO_BUMP_ON");
		bool maskOn = keyWords.Contains("MARMO_LAYER_MASK_TEXTURE_UV0") || keyWords.Contains("MARMO_LAYER_MASK_TEXTURE_UV1");

		serializedObject.Update();
		SerializedProperty theShader = serializedObject.FindProperty("m_Shader");
		if(isVisible && !theShader.hasMultipleDifferentValues && theShader.objectReferenceValue != null) {

			EditorGUI.BeginChangeCheck();
			MaterialProperty[] props = MaterialEditor.GetMaterialProperties(targets);

			PropertyBlock headerBlock = null;
			bool prevVisible = true;
			for(int i = 0; i < props.Length; i++) {
				if( (props[i].flags & MaterialProperty.PropFlags.HideInInspector) > 0 ) continue;

				bool enabled = true;
				bool visible = true;
				string name = props[i].name;
				string label = props[i].displayName;
				string subLabel = "";

				if( name == "Header_Layer1" || name == "Header_Layer2" || name == "Header_Layer3" ) {
					visible = fourLayerOn;
				}

				if( name == "Header_Layer1" ) {
					visible |= twoLayerOn;
				}

				//is this property a header to a new block?
				bool header = blocks.ContainsKey(name);

				//starting a new header
				if( header && visible ) {
					// if a previous block is still open, add a little space to the end (helps get a little GUI nudge when unrolling empty blocks).
					if( headerBlock != null && headerBlock.open ) {
						GUILayout.Space(2);
					}
					if( headerBlock != null ) {
						Rect r = EditorGUILayout.GetControlRect();
						Vector2 a = r.center; a.x = 0;
						Vector2 b = r.center; b.x = Screen.width;
						Drawing.DrawLine(a, b, Color.grey, 1f, false);
					}
					// new block started
					headerBlock = blocks[name];
				}

				if(name == "_MainTex" || name == "_MainTex1" || name == "_MainTex2" || name == "_MainTex3" ) {
					if( diffSpecOn ) label = "Diffuse(RGB) Specular(A)";
					else 			 label = "Diffuse(RGBA)";
				} 

				if( name == "_LayerMask" ) {
					visible = maskOn && (fourLayerOn || twoLayerOn);
				}

				if(name == ("_MainTex1") || name == ("_MainTex2") || name == ("_MainTex3") ||
				   name == ("_Color1")   || name == ("_Color2")   || name == ("_Color3")   || 
				   name == ("_SpecTex1") || name == ("_SpecTex2") || name == ("_SpecTex3") ||
				   name == ("_Fresnel1") || name == ("_Fresnel2") || name == ("_Fresnel3") ||
				   name == ("_BumpMap1") || name == ("_BumpMap2") || name == ("_BumpMap3")) {
					visible = fourLayerOn;
				}

				if(name == "_MainTex1" || name == "_Color1" || name == "_SpecTex1" || name == "_Fresnel1" || name == "_BumpMap1" ) {
					visible |= twoLayerOn;
				}

				//unless diff-spec is enabled, bump3 and spec3 are disabled, not enough texture samplers for them
				if( name == "_BumpMap3" || name == "_SpecTex3" || name == "_Fresnel3" ) {
					visible &= diffSpecOn;
				}
				
				if(name.Contains("_SpecTex") || name.Contains("_Fresnel")) {
					visible &= specOn;
				}
				if(name.Contains("_BumpMap")) {
					visible &= bumpOn;
				}
				if(name == "_SpecTex" || name == "_SpecTex1" || name == "_SpecTex2" || name == "_SpecTex3") {
					visible &= !diffSpecOn; 
				}

				// texture tiling is copied from the texture scaleOffset fields
				if( props[i].type == MaterialProperty.PropType.Texture ) {
					targetMat.SetVector(name + "Tiling", props[i].textureScaleAndOffset);
				}

				// link tiling attributes of textures to the textures themselves
				//NOTE: tiling settings must come immediately after texture slots
				if( name.Contains("Tiling") ) { visible = prevVisible; }

				if( headerBlock != null && !header ) {
					visible &= headerBlock.enabled;
					visible &= headerBlock.open;
				}

				// draw each header type and update the appropriate flags
				if( visible ) {
					if(header)	DrawPropertyHeader(headerBlock, props[i], label);
					else 		DrawProperty(props[i], label, subLabel, !enabled);
				}
				prevVisible = visible;

			}
			if(EditorGUI.EndChangeCheck()) PropertiesChanged();
		}
	}
}


