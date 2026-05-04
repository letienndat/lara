//
//  SettingsView.swift
//  lara
//
//  Created by ruter on 29.03.26.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var mgr: laramgr
    @Binding var hasoffsets: Bool
    @State private var showresetalert: Bool = false
    @State private var downloadingkernelcache = false
    @State private var showkcacheimporter: Bool = false
    @State private var importingkernelcache: Bool = false
    @State private var showkcachetips: Bool = false
    @State private var statusmsg: String?
    @AppStorage("loggernobullshit") private var loggernobullshit: Bool = true
    @AppStorage("keepalive") private var iskeepalive: Bool = true
    @AppStorage("showfmintabs") private var showfmintabs: Bool = true
    @AppStorage("selectedMethod") private var selectedMethod: method = .hybrid
    @AppStorage("rcdockunlimited") private var rcdockunlimited: Bool = false
    @AppStorage("stashkrw") private var stashkrw: Bool = false
    @AppStorage("selectedFmAppsDisplayMode") private var selectedFmAppsDisplayMode: fmAppsDisplayMode = .appName
    @AppStorage("fmRecursiveSearch") private var fmRecursiveSearch: Bool = false
    
    @State private var editableoffsets: [String: String] = [:]
    @State private var offsetsloaded: Bool = false
    
    private let offsetnames = [
        "off_inpcb_inp_list_le_next", "off_inpcb_inp_pcbinfo", "off_inpcb_inp_socket",
        "off_inpcbinfo_ipi_zone", "off_inpcb_inp_depend6_inp6_icmp6filt", "off_inpcb_inp_depend6_inp6_chksum",
        "off_socket_so_usecount", "off_socket_so_proto", "off_socket_so_background_thread",
        "off_kalloc_type_view_kt_zv_zv_name",
        "off_thread_t_tro", "off_thread_ro_tro_proc", "off_thread_ro_tro_task",
        "off_thread_machine_upcb", "off_thread_machine_contextdata", "off_thread_ctid",
        "off_thread_options", "off_thread_mutex_lck_mtx_data", "off_thread_machine_kstackptr",
        "off_thread_machine_jop_pid", "off_thread_machine_rop_pid",
        "off_thread_guard_exc_info_code", "off_thread_mach_exc_info_code",
        "off_thread_mach_exc_info_os_reason", "off_thread_mach_exc_info_exception_type",
        "off_thread_ast", "off_thread_task_threads_next",
        "off_proc_p_list_le_next", "off_proc_p_list_le_prev", "off_proc_p_proc_ro",
        "off_proc_p_pid", "off_proc_p_fd", "off_proc_p_flag", "off_proc_p_textvp", "off_proc_p_name",
        "off_proc_ro_pr_task", "off_proc_ro_p_ucred", "off_ucred_cr_label",
        "off_task_itk_space", "off_task_threads_next", "off_task_task_exc_guard", "off_task_map",
        "off_filedesc_fd_ofiles", "off_filedesc_fd_cdir", "off_fileproc_fp_glob",
        "off_fileglob_fg_data", "off_fileglob_fg_flag",
        "off_vnode_v_ncchildren_tqh_first", "off_vnode_v_nclinks_lh_first", "off_vnode_v_parent",
        "off_vnode_v_data", "off_vnode_v_name", "off_vnode_v_usecount", "off_vnode_v_iocount",
        "off_vnode_v_writecount", "off_vnode_v_flag", "off_vnode_v_mount",
        "off_mount_mnt_flag",
        "off_namecache_nc_vp", "off_namecache_nc_child_tqe_next",
        "off_arm_saved_state64_lr", "off_arm_saved_state64_pc", "off_arm_saved_state_uss_ss_64",
        "off_ipc_space_is_table", "off_ipc_entry_ie_object", "off_ipc_port_ip_kobject",
        "off_arm_kernel_saved_state_sp",
        "off_vm_map_hdr", "off_vm_map_header_nentries", "off_vm_map_entry_links_next",
        "off_vm_map_entry_vme_object_or_delta", "off_vm_map_entry_vme_alias",
        "off_vm_map_header_links_next",
        "off_vm_object_vo_un1_vou_size", "off_vm_object_ref_count",
        "off_vm_named_entry_backing_copy", "off_vm_named_entry_size",
        "off_label_l_perpolicy_amfi", "off_label_l_perpolicy_sandbox",
        "sizeof_ipc_entry", "t1sz_boot"
    ]
    
    private let readonlyoffsets = [
        ("smr_base", "smr"), ("VM_MIN_KERNEL_ADDRESS", "vmmin"), ("VM_MAX_KERNEL_ADDRESS", "vmmax")
    ]
    
    private var offsetview: some View {
        ForEach(offsetnames, id: \.self) { name in
            HStack {
                Text(name)
                Spacer()
                TextField("0x0", text: Binding(
                    get: { editableoffsets[name, default: "0x0"] },
                    set: { editableoffsets[name] = $0 }
                ))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
                .monospaced()
            }
        }
    }
    
    private var readonlyview: some View {
        ForEach(readonlyoffsets, id: \.0) { name, key in
            HStack {
                Text(name)
                Spacer()
                Text(editableoffsets[key, default: "0x0"])
                    .foregroundColor(.secondary)
                    .monospaced()
            }
        }
    }
    
    private func initOffsetStates() {
        guard !offsetsloaded else { return }
        var dict: [String: String] = [:]
        dict["off_inpcb_inp_list_le_next"] = String(format: "0x%x", off_inpcb_inp_list_le_next)
        dict["off_inpcb_inp_pcbinfo"] = String(format: "0x%x", off_inpcb_inp_pcbinfo)
        dict["off_inpcb_inp_socket"] = String(format: "0x%x", off_inpcb_inp_socket)
        dict["off_inpcbinfo_ipi_zone"] = String(format: "0x%x", off_inpcbinfo_ipi_zone)
        dict["off_inpcb_inp_depend6_inp6_icmp6filt"] = String(format: "0x%x", off_inpcb_inp_depend6_inp6_icmp6filt)
        dict["off_inpcb_inp_depend6_inp6_chksum"] = String(format: "0x%x", off_inpcb_inp_depend6_inp6_chksum)
        dict["off_socket_so_usecount"] = String(format: "0x%x", off_socket_so_usecount)
        dict["off_socket_so_proto"] = String(format: "0x%x", off_socket_so_proto)
        dict["off_socket_so_background_thread"] = String(format: "0x%x", off_socket_so_background_thread)
        dict["off_kalloc_type_view_kt_zv_zv_name"] = String(format: "0x%x", off_kalloc_type_view_kt_zv_zv_name)
        dict["off_thread_t_tro"] = String(format: "0x%x", off_thread_t_tro)
        dict["off_thread_ro_tro_proc"] = String(format: "0x%x", off_thread_ro_tro_proc)
        dict["off_thread_ro_tro_task"] = String(format: "0x%x", off_thread_ro_tro_task)
        dict["off_thread_machine_upcb"] = String(format: "0x%x", off_thread_machine_upcb)
        dict["off_thread_machine_contextdata"] = String(format: "0x%x", off_thread_machine_contextdata)
        dict["off_thread_ctid"] = String(format: "0x%x", off_thread_ctid)
        dict["off_thread_options"] = String(format: "0x%x", off_thread_options)
        dict["off_thread_mutex_lck_mtx_data"] = String(format: "0x%x", off_thread_mutex_lck_mtx_data)
        dict["off_thread_machine_kstackptr"] = String(format: "0x%x", off_thread_machine_kstackptr)
        dict["off_thread_machine_jop_pid"] = String(format: "0x%x", off_thread_machine_jop_pid)
        dict["off_thread_machine_rop_pid"] = String(format: "0x%x", off_thread_machine_rop_pid)
        dict["off_thread_guard_exc_info_code"] = String(format: "0x%x", off_thread_guard_exc_info_code)
        dict["off_thread_mach_exc_info_code"] = String(format: "0x%x", off_thread_mach_exc_info_code)
        dict["off_thread_mach_exc_info_os_reason"] = String(format: "0x%x", off_thread_mach_exc_info_os_reason)
        dict["off_thread_mach_exc_info_exception_type"] = String(format: "0x%x", off_thread_mach_exc_info_exception_type)
        dict["off_thread_ast"] = String(format: "0x%x", off_thread_ast)
        dict["off_thread_task_threads_next"] = String(format: "0x%x", off_thread_task_threads_next)
        dict["off_proc_p_list_le_next"] = String(format: "0x%x", off_proc_p_list_le_next)
        dict["off_proc_p_list_le_prev"] = String(format: "0x%x", off_proc_p_list_le_prev)
        dict["off_proc_p_proc_ro"] = String(format: "0x%x", off_proc_p_proc_ro)
        dict["off_proc_p_pid"] = String(format: "0x%x", off_proc_p_pid)
        dict["off_proc_p_fd"] = String(format: "0x%x", off_proc_p_fd)
        dict["off_proc_p_flag"] = String(format: "0x%x", off_proc_p_flag)
        dict["off_proc_p_textvp"] = String(format: "0x%x", off_proc_p_textvp)
        dict["off_proc_p_name"] = String(format: "0x%x", off_proc_p_name)
        dict["off_proc_ro_pr_task"] = String(format: "0x%x", off_proc_ro_pr_task)
        dict["off_proc_ro_p_ucred"] = String(format: "0x%x", off_proc_ro_p_ucred)
        dict["off_ucred_cr_label"] = String(format: "0x%x", off_ucred_cr_label)
        dict["off_task_itk_space"] = String(format: "0x%x", off_task_itk_space)
        dict["off_task_threads_next"] = String(format: "0x%x", off_task_threads_next)
        dict["off_task_task_exc_guard"] = String(format: "0x%x", off_task_task_exc_guard)
        dict["off_task_map"] = String(format: "0x%x", off_task_map)
        dict["off_filedesc_fd_ofiles"] = String(format: "0x%x", off_filedesc_fd_ofiles)
        dict["off_filedesc_fd_cdir"] = String(format: "0x%x", off_filedesc_fd_cdir)
        dict["off_fileproc_fp_glob"] = String(format: "0x%x", off_fileproc_fp_glob)
        dict["off_fileglob_fg_data"] = String(format: "0x%x", off_fileglob_fg_data)
        dict["off_fileglob_fg_flag"] = String(format: "0x%x", off_fileglob_fg_flag)
        dict["off_vnode_v_ncchildren_tqh_first"] = String(format: "0x%x", off_vnode_v_ncchildren_tqh_first)
        dict["off_vnode_v_nclinks_lh_first"] = String(format: "0x%x", off_vnode_v_nclinks_lh_first)
        dict["off_vnode_v_parent"] = String(format: "0x%x", off_vnode_v_parent)
        dict["off_vnode_v_data"] = String(format: "0x%x", off_vnode_v_data)
        dict["off_vnode_v_name"] = String(format: "0x%x", off_vnode_v_name)
        dict["off_vnode_v_usecount"] = String(format: "0x%x", off_vnode_v_usecount)
        dict["off_vnode_v_iocount"] = String(format: "0x%x", off_vnode_v_iocount)
        dict["off_vnode_v_writecount"] = String(format: "0x%x", off_vnode_v_writecount)
        dict["off_vnode_v_flag"] = String(format: "0x%x", off_vnode_v_flag)
        dict["off_vnode_v_mount"] = String(format: "0x%x", off_vnode_v_mount)
        dict["off_mount_mnt_flag"] = String(format: "0x%x", off_mount_mnt_flag)
        dict["off_namecache_nc_vp"] = String(format: "0x%x", off_namecache_nc_vp)
        dict["off_namecache_nc_child_tqe_next"] = String(format: "0x%x", off_namecache_nc_child_tqe_next)
        dict["off_arm_saved_state64_lr"] = String(format: "0x%x", off_arm_saved_state64_lr)
        dict["off_arm_saved_state64_pc"] = String(format: "0x%x", off_arm_saved_state64_pc)
        dict["off_arm_saved_state_uss_ss_64"] = String(format: "0x%x", off_arm_saved_state_uss_ss_64)
        dict["off_ipc_space_is_table"] = String(format: "0x%x", off_ipc_space_is_table)
        dict["off_ipc_entry_ie_object"] = String(format: "0x%x", off_ipc_entry_ie_object)
        dict["off_ipc_port_ip_kobject"] = String(format: "0x%x", off_ipc_port_ip_kobject)
        dict["off_arm_kernel_saved_state_sp"] = String(format: "0x%x", off_arm_kernel_saved_state_sp)
        dict["off_vm_map_hdr"] = String(format: "0x%x", off_vm_map_hdr)
        dict["off_vm_map_header_nentries"] = String(format: "0x%x", off_vm_map_header_nentries)
        dict["off_vm_map_entry_links_next"] = String(format: "0x%x", off_vm_map_entry_links_next)
        dict["off_vm_map_entry_vme_object_or_delta"] = String(format: "0x%x", off_vm_map_entry_vme_object_or_delta)
        dict["off_vm_map_entry_vme_alias"] = String(format: "0x%x", off_vm_map_entry_vme_alias)
        dict["off_vm_map_header_links_next"] = String(format: "0x%x", off_vm_map_header_links_next)
        dict["off_vm_object_vo_un1_vou_size"] = String(format: "0x%x", off_vm_object_vo_un1_vou_size)
        dict["off_vm_object_ref_count"] = String(format: "0x%x", off_vm_object_ref_count)
        dict["off_vm_named_entry_backing_copy"] = String(format: "0x%x", off_vm_named_entry_backing_copy)
        dict["off_vm_named_entry_size"] = String(format: "0x%x", off_vm_named_entry_size)
        dict["off_label_l_perpolicy_amfi"] = String(format: "0x%x", off_label_l_perpolicy_amfi)
        dict["off_label_l_perpolicy_sandbox"] = String(format: "0x%x", off_label_l_perpolicy_sandbox)
        dict["sizeof_ipc_entry"] = String(format: "0x%x", sizeof_ipc_entry)
        dict["t1sz_boot"] = String(format: "0x%llx", t1sz_boot)
        dict["smr"] = hex(smr_base)
        dict["vmmin"] = hex(VM_MIN_KERNEL_ADDRESS)
        dict["vmmax"] = hex(VM_MAX_KERNEL_ADDRESS)
        DispatchQueue.main.async {
            editableoffsets = dict
            offsetsloaded = true
        }
    }
    
    private func applyOffsetStates() {
        func setoff(_ key: String, _ setter: (UInt32) -> Void) {
            if let raw = editableoffsets[key] {
                let cleaned = raw.replacingOccurrences(of: "0x", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                if let value = UInt32(cleaned, radix: 16) { setter(value) }
            }
        }
        setoff("off_inpcb_inp_list_le_next") { off_inpcb_inp_list_le_next = $0 }
        setoff("off_inpcb_inp_pcbinfo") { off_inpcb_inp_pcbinfo = $0 }
        setoff("off_inpcb_inp_socket") { off_inpcb_inp_socket = $0 }
        setoff("off_inpcbinfo_ipi_zone") { off_inpcbinfo_ipi_zone = $0 }
        setoff("off_inpcb_inp_depend6_inp6_icmp6filt") { off_inpcb_inp_depend6_inp6_icmp6filt = $0 }
        setoff("off_inpcb_inp_depend6_inp6_chksum") { off_inpcb_inp_depend6_inp6_chksum = $0 }
        setoff("off_socket_so_usecount") { off_socket_so_usecount = $0 }
        setoff("off_socket_so_proto") { off_socket_so_proto = $0 }
        setoff("off_socket_so_background_thread") { off_socket_so_background_thread = $0 }
        setoff("off_kalloc_type_view_kt_zv_zv_name") { off_kalloc_type_view_kt_zv_zv_name = $0 }
        setoff("off_thread_t_tro") { off_thread_t_tro = $0 }
        setoff("off_thread_ro_tro_proc") { off_thread_ro_tro_proc = $0 }
        setoff("off_thread_ro_tro_task") { off_thread_ro_tro_task = $0 }
        setoff("off_thread_machine_upcb") { off_thread_machine_upcb = $0 }
        setoff("off_thread_machine_contextdata") { off_thread_machine_contextdata = $0 }
        setoff("off_thread_ctid") { off_thread_ctid = $0 }
        setoff("off_thread_options") { off_thread_options = $0 }
        setoff("off_thread_mutex_lck_mtx_data") { off_thread_mutex_lck_mtx_data = $0 }
        setoff("off_thread_machine_kstackptr") { off_thread_machine_kstackptr = $0 }
        setoff("off_thread_machine_jop_pid") { off_thread_machine_jop_pid = $0 }
        setoff("off_thread_machine_rop_pid") { off_thread_machine_rop_pid = $0 }
        setoff("off_thread_guard_exc_info_code") { off_thread_guard_exc_info_code = $0 }
        setoff("off_thread_mach_exc_info_code") { off_thread_mach_exc_info_code = $0 }
        setoff("off_thread_mach_exc_info_os_reason") { off_thread_mach_exc_info_os_reason = $0 }
        setoff("off_thread_mach_exc_info_exception_type") { off_thread_mach_exc_info_exception_type = $0 }
        setoff("off_thread_ast") { off_thread_ast = $0 }
        setoff("off_thread_task_threads_next") { off_thread_task_threads_next = $0 }
        setoff("off_proc_p_list_le_next") { off_proc_p_list_le_next = $0 }
        setoff("off_proc_p_list_le_prev") { off_proc_p_list_le_prev = $0 }
        setoff("off_proc_p_proc_ro") { off_proc_p_proc_ro = $0 }
        setoff("off_proc_p_pid") { off_proc_p_pid = $0 }
        setoff("off_proc_p_fd") { off_proc_p_fd = $0 }
        setoff("off_proc_p_flag") { off_proc_p_flag = $0 }
        setoff("off_proc_p_textvp") { off_proc_p_textvp = $0 }
        setoff("off_proc_p_name") { off_proc_p_name = $0 }
        setoff("off_proc_ro_pr_task") { off_proc_ro_pr_task = $0 }
        setoff("off_proc_ro_p_ucred") { off_proc_ro_p_ucred = $0 }
        setoff("off_ucred_cr_label") { off_ucred_cr_label = $0 }
        setoff("off_task_itk_space") { off_task_itk_space = $0 }
        setoff("off_task_threads_next") { off_task_threads_next = $0 }
        setoff("off_task_task_exc_guard") { off_task_task_exc_guard = $0 }
        setoff("off_task_map") { off_task_map = $0 }
        setoff("off_filedesc_fd_ofiles") { off_filedesc_fd_ofiles = $0 }
        setoff("off_filedesc_fd_cdir") { off_filedesc_fd_cdir = $0 }
        setoff("off_fileproc_fp_glob") { off_fileproc_fp_glob = $0 }
        setoff("off_fileglob_fg_data") { off_fileglob_fg_data = $0 }
        setoff("off_fileglob_fg_flag") { off_fileglob_fg_flag = $0 }
        setoff("off_vnode_v_ncchildren_tqh_first") { off_vnode_v_ncchildren_tqh_first = $0 }
        setoff("off_vnode_v_nclinks_lh_first") { off_vnode_v_nclinks_lh_first = $0 }
        setoff("off_vnode_v_parent") { off_vnode_v_parent = $0 }
        setoff("off_vnode_v_data") { off_vnode_v_data = $0 }
        setoff("off_vnode_v_name") { off_vnode_v_name = $0 }
        setoff("off_vnode_v_usecount") { off_vnode_v_usecount = $0 }
        setoff("off_vnode_v_iocount") { off_vnode_v_iocount = $0 }
        setoff("off_vnode_v_writecount") { off_vnode_v_writecount = $0 }
        setoff("off_vnode_v_flag") { off_vnode_v_flag = $0 }
        setoff("off_vnode_v_mount") { off_vnode_v_mount = $0 }
        setoff("off_mount_mnt_flag") { off_mount_mnt_flag = $0 }
        setoff("off_namecache_nc_vp") { off_namecache_nc_vp = $0 }
        setoff("off_namecache_nc_child_tqe_next") { off_namecache_nc_child_tqe_next = $0 }
        setoff("off_arm_saved_state64_lr") { off_arm_saved_state64_lr = $0 }
        setoff("off_arm_saved_state64_pc") { off_arm_saved_state64_pc = $0 }
        setoff("off_arm_saved_state_uss_ss_64") { off_arm_saved_state_uss_ss_64 = $0 }
        setoff("off_ipc_space_is_table") { off_ipc_space_is_table = $0 }
        setoff("off_ipc_entry_ie_object") { off_ipc_entry_ie_object = $0 }
        setoff("off_ipc_port_ip_kobject") { off_ipc_port_ip_kobject = $0 }
        setoff("off_arm_kernel_saved_state_sp") { off_arm_kernel_saved_state_sp = $0 }
        setoff("off_vm_map_hdr") { off_vm_map_hdr = $0 }
        setoff("off_vm_map_header_nentries") { off_vm_map_header_nentries = $0 }
        setoff("off_vm_map_entry_links_next") { off_vm_map_entry_links_next = $0 }
        setoff("off_vm_map_entry_vme_object_or_delta") { off_vm_map_entry_vme_object_or_delta = $0 }
        setoff("off_vm_map_entry_vme_alias") { off_vm_map_entry_vme_alias = $0 }
        setoff("off_vm_map_header_links_next") { off_vm_map_header_links_next = $0 }
        setoff("off_vm_object_vo_un1_vou_size") { off_vm_object_vo_un1_vou_size = $0 }
        setoff("off_vm_object_ref_count") { off_vm_object_ref_count = $0 }
        setoff("off_vm_named_entry_backing_copy") { off_vm_named_entry_backing_copy = $0 }
        setoff("off_vm_named_entry_size") { off_vm_named_entry_size = $0 }
        setoff("off_label_l_perpolicy_amfi") { off_label_l_perpolicy_amfi = $0 }
        setoff("off_label_l_perpolicy_sandbox") { off_label_l_perpolicy_sandbox = $0 }
        setoff("sizeof_ipc_entry") { sizeof_ipc_entry = $0 }
        if let raw = editableoffsets["t1sz_boot"] {
            let cleaned = raw.replacingOccurrences(of: "0x", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            if let v = UInt64(cleaned, radix: 16) { t1sz_boot = v }
        }
    }
    
    var appname: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? "Unknown App"
    }
    var appversion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }
    var appicon: UIImage {
        if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let files = primary["CFBundleIconFiles"] as? [String],
           let last = files.last,
           let image = UIImage(named: last) {
            return image
        }
        
        return UIImage(named: "unknown") ?? UIImage()
    }
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        Image(uiImage: appicon)
                            .resizable()
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        VStack(alignment: .leading) {
                            Text(appname)
                                .font(.headline)
                            
                            Text("Version \(appversion)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Lara")
                }
                
                Section {
                    Picker("", selection: $selectedMethod) {
                        ForEach(method.allCases, id: \.self) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Method")
                } footer: {
                    if selectedMethod == .vfs {
                        Text("VFS only.")
                    } else if selectedMethod == .sbx {
                        Text("SBX only.")
                    } else {
                        Text("Hybrid: SBX for read, VFS for write.\nBest method ever. (Thanks Huy)")
                    }
                }
                
                Section {
                    Toggle("Disable log dividers", isOn: $loggernobullshit)
                        .onChange(of: loggernobullshit) { _ in
                            globallogger.clear()
                        }
                    
                    Toggle("Keep Alive", isOn: $iskeepalive)
                        .onChange(of: iskeepalive) { _ in
                            if iskeepalive {
                                if !kaenabled { toggleka() }
                            } else {
                                if kaenabled { toggleka() }
                            }
                        }
                    
                    Toggle("Show File Manager in Tabs", isOn: $showfmintabs)
                    Toggle("Enable recursive search in File Manager", isOn: $fmRecursiveSearch)
                } header: {
                    Text("Lara Settings")
                } footer: {
                    Text("Keep Alive keeps the app running in the background when it is minimized (not closed from app switcher).")
                }

                Section {
                    Picker("Display Mode", selection: $selectedFmAppsDisplayMode) {
                        ForEach(fmAppsDisplayMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("File Manager App Management")
                } footer: {
                    Text("Change the way app folders get displayed in the file manager.")
                }

                #if !DISABLE_REMOTECALL
                Section {
                    Toggle("Stash KRW primitives", isOn: $stashkrw)
                    Toggle("Allow >10 dock icons", isOn: $rcdockunlimited)
                } header: {
                    Text("RemoteCall")
                }
                #endif

                Section {
                    if !hasoffsets {
                        Button("Download Kernelcache") {
                            guard !downloadingkernelcache else { return }
                            downloadingkernelcache = true
                            DispatchQueue.global(qos: .userInitiated).async {
                                let ok = dlkerncache()
                                DispatchQueue.main.async {
                                    hasoffsets = ok
                                    downloadingkernelcache = false
                                }
                            }
                        }
                        .disabled(downloadingkernelcache)
                        
                        Button("Fetch Kernelcache") {
                            mgr.run()
                        }
                        
                        HStack {
                            Button("Import Kernelcache from Files") {
                                guard !importingkernelcache else { return }
                                showkcacheimporter = true
                            }
                            .disabled(importingkernelcache)
                            
                            Spacer()
                            
                            Button {
                                showkcachetips.toggle()
                            } label: {
                                Image(systemName: "lightbulb.max.fill")
                            }
                        }
                    }
                    
                    Button {
                        showresetalert = true
                    } label: {
                        Text("Delete Kernelcache Data")
                            .foregroundColor(.red)
                    }
                } header: {
                    Text("Kernelcache")
                } footer: {
                    if !showkcachetips {
                        Text("Deleting and redownloading Kernelcache can fix a lot of issues. Try this before making a github Issue.")
                    }
                }
                
                if showkcachetips {
                    Section {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("How to obtain a kernelcache (macOS)")
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(.primary)
                            
                            Text("1. Download the IPSW tool for your device.")
                            Link("https://github.com/blacktop/ipsw/releases",
                                 destination: URL(string: "https://github.com/blacktop/ipsw/releases")!)
                            
                            Text("2. Extract the archive.")
                            Text("3. Open Terminal.")
                            Text("4. Navigate to the extracted folder:")
                            Text("cd /path/to/ipsw_3.1.671_something_something/")
                                .font(.system(.caption2, design: .monospaced))
                                .textSelection(.enabled)
                                .foregroundColor(.primary)
                            
                            Text("5. Extract the kernel:")
                            Text("./ipsw extract --kernel [drag your ipsw here]")
                                .font(.system(.caption2, design: .monospaced))
                                .textSelection(.enabled)
                                .foregroundColor(.primary)
                            
                            Text("6. Get the kernelcache file.")
                            Text("7. Transfer the kernelcache to your iCloud or iPhone.")
                            Text("8. Tap the button above and select the kernelcache, for example kernelcache.release.iPhone14,3.")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                    } footer: {
                        Text("Deleting and redownloading Kernelcache can fix a lot of issues. Try this before making a github Issue.")
                    }
                }
                
                if isdebugged() {
                    Section {
                        Button {
                            exit(0)
                        } label: {
                            Text("Detach")
                        }
                        .foregroundColor(.red)
                    } header: {
                        Text("Debugger")
                    } footer: {
                        Text("Lara does not work when a debugger is attached.")
                    }
                }
                
                Section {
                    NavigationLink("Modify Offsets") {
                        List {
                            offsetview
                            readonlyview
                        }
                        .onAppear { initOffsetStates() }
                    }
                    Button {
                        save()
                        statusmsg = "Offsets saved!"
                    } label: {
                        Text("Save Offsets")
                    }
                } header: {
                    Text("offsets")
                } footer: {
                    Text("Manually edit and save offsets. Values persist across launches.")
                }
                
                Section {
                    HStack(alignment: .top) {
                        AsyncImage(url: URL(string: "https://github.com/rooootdev.png")) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text("roooot")
                                .font(.headline)
                            
                            Text("Main Developer")
                                .font(.subheadline)
                                .foregroundColor(Color.secondary)
                        }
                        
                        Spacer()
                    }
                    .onTapGesture {
                        if let url = URL(string: "https://github.com/rooootdev"),
                           UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }
                    
                    HStack(alignment: .top) {
                        AsyncImage(url: URL(string: "https://github.com/wh1te4ever.png")) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text("wh1te4ever")
                                .font(.headline)
                            
                            Text("Made darksword-kexploit-fun.")
                                .font(.subheadline)
                                .foregroundColor(Color.secondary)
                        }
                        
                        Spacer()
                    }
                    .onTapGesture {
                        if let url = URL(string: "https://github.com/wh1te4ever"),
                           UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }
                    
                    HStack(alignment: .top) {
                        AsyncImage(url: URL(string: "https://github.com/khanhduytran0.png")) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text("Duy Tran")
                                .font(.headline)
                            
                            Text("Various remotecall-related improvements and features.")
                                .font(.subheadline)
                                .foregroundColor(Color.secondary)
                        }
                        
                        Spacer()
                    }
                    .onTapGesture {
                        if let url = URL(string: "https://github.com/khanhduytran0"),
                           UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }
                    
                    HStack(alignment: .top) {
                        AsyncImage(url: URL(string: "https://github.com/AppInstalleriOSGH.png")) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text("AppInstaller iOS")
                                .font(.headline)
                            
                            Text("Helped me with offsets and lots of other stuff. This project wouldnt have been possible without him!")
                                .font(.subheadline)
                                .foregroundColor(Color.secondary)
                        }
                        
                        Spacer()
                    }
                    .onTapGesture {
                        if let url = URL(string: "https://github.com/AppInstalleriOSGH"),
                           UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }
                    
                    HStack(alignment: .top) {
                        AsyncImage(url: URL(string: "https://github.com/jailbreakdotparty.png")) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text("jailbreak.party")
                                .font(.headline)
                            
                            Text("All of the DirtyZero tweaks.")
                                .font(.subheadline)
                                .foregroundColor(Color.secondary)
                        }
                        
                        Spacer()
                    }
                    .onTapGesture {
                        if let url = URL(string: "https://github.com/jailbreakdotparty"),
                           UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }
                    
                    HStack(alignment: .top) {
                        AsyncImage(url: URL(string: "https://github.com/jurre111.png")) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text("Jurre")
                                .font(.headline)
                            
                            Text("EditorView, PocketPoster Helper, various improvements.")
                                .font(.subheadline)
                                .foregroundColor(Color.secondary)
                        }
                        
                        Spacer()
                    }
                    .onTapGesture {
                        if let url = URL(string: "https://github.com/jurre111"),
                           UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }
                    
                    HStack(alignment: .top) {
                        AsyncImage(url: URL(string: "https://github.com/neonmodder123.png")) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text("neon")
                                .font(.headline)
                            
                            Text("Made the respring script.")
                                .font(.subheadline)
                                .foregroundColor(Color.secondary)
                        }
                        
                        Spacer()
                    }
                    .onTapGesture {
                        if let url = URL(string: "https://github.com/neonmodder123"),
                           UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }
                } header: {
                    Text("Credits")
                }
            }
            .navigationTitle("Settings")
        }
        .fileImporter(isPresented: $showkcacheimporter,
                      allowedContentTypes: [.data],
                      allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                importingkernelcache = true
                DispatchQueue.global(qos: .userInitiated).async {
                    var ok = false
                    let shouldStopAccess = url.startAccessingSecurityScopedResource()
                    defer {
                        if shouldStopAccess {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }
                    let fm = FileManager.default
                    if let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first {
                        let dest = docs.appendingPathComponent("kernelcache")
                        do {
                            if fm.fileExists(atPath: dest.path) {
                                try fm.removeItem(at: dest)
                            }
                            try fm.copyItem(at: url, to: dest)
                            ok = dlkerncache()
                        } catch {
                            print("failed to import kernelcache: \(error)")
                            ok = false
                        }
                    }
                    DispatchQueue.main.async {
                        hasoffsets = ok
                        importingkernelcache = false
                    }
                }
            case .failure:
                break
            }
        }
        .alert("Clear Kernelcache Data?", isPresented: $showresetalert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                clearkerncachedata()
            }
        } message: {
            Text("This will delete the downloaded kernelcache and remove saved offsets.")
        }
        .alert("Status", isPresented: .constant(statusmsg != nil)) {
            Button("OK") { statusmsg = nil }
        } message: {
            Text(statusmsg ?? "")
        }
    }
    
    private func clearkerncachedata() {
        let fm = FileManager.default
        
        UserDefaults.standard.removeObject(forKey: "lara.kernelcache_path")
        UserDefaults.standard.removeObject(forKey: "lara.kernelcache_size")
        
        let docsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let kernelcacheDocPath = docsPath.appendingPathComponent("kernelcache")
        
        do {
            if fm.fileExists(atPath: kernelcacheDocPath.path) {
                try fm.removeItem(at: kernelcacheDocPath)
                mgr.logmsg("Deleted kernelcache from Documents")
            }
        } catch {
            mgr.logmsg("Failed to delete kernelcache: \(error.localizedDescription)")
        }
        
        let tempPath = NSTemporaryDirectory()
        let tempFiles = ["kernelcache.release.ipad", "kernelcache.release.iphone", "kernelcache.release.ipad3", "kernelcache.release.iphone14,3"]
        
        for file in tempFiles {
            let path = tempPath + file
            do {
                if fm.fileExists(atPath: path) {
                    try fm.removeItem(atPath: path)
                    mgr.logmsg("Deleted temp kernelcache: \(file)")
                }
            } catch {
                mgr.logmsg("Failed to delete \(file): \(error.localizedDescription)")
            }
        }
        
        mgr.logmsg("Kernelcache data cleared")
        hasoffsets = false
    }
    
    private func save() {
        applyOffsetStates()
        savealloffsets()
        mgr.logmsg("Saved all offsets")
    }
}

enum method: String, CaseIterable {
    case vfs = "VFS"
    case sbx = "SBX"
    case hybrid = "Hybrid"
}

enum fmAppsDisplayMode: String, CaseIterable {
    case UUID = "UUID"
    case bundleID = "Bundle ID"
    case appName = "App Name"
}
