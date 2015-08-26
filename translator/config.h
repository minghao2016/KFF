#ifndef _CONFIG_H_
#define _CONFIG_H_


namespace kff {
namespace translator {

class Configuration{
 public:
  enum ConfigKey {
    CUDA_BLOCK_SIZE,
    MULTISTREAM_BOUNDARY,
    TRACE_KERNEL,
    CUDA_KERNEL_ERROR_CHECK
    };
  Configuration() {
    AddKey(CUDA_BLOCK_SIZE, "CUDA_BLOCK_SIZE");
    AddKey(MULTISTREAM_BOUNDARY, "MULTISTREAM_BOUNDARY");  
    auto_tuning_ = false; /* set default value */
    AddKey(TRACE_KERNEL, "TRACE_KERNEL");
    AddKey(CUDA_KERNEL_ERROR_CHECK, "CUDA_KERNEL_ERROR_CHECK");    
  }
  virtual ~Configuration() {}
  const pu::LuaValue *Lookup(ConfigKey key) const {
    return LookupInternal((int)key);
  }

  /** auto tuning parameters: code pattern */
  static const std::string at_params_pattern[];
  /** auto tuning parameters: dynamic argument */
  static const std::string at_params_dynamic[];
  /** load configuration file, no auto tuning
   * @param[in] path ... configuration filename
   * @return    0
   */
  int LoadFile(const std::string &path) { return LoadFile(path, false); }
  /** load configuration file, auto tuning or not
   * @param[in] path ... configuration filename
   * @param[in] at ... auto tuning flag
   * @return    0
   */
  int LoadFile(const std::string &path, bool at);
  /** set pattern
   * @param[in] pat ... index of pattern
   * @return    number of patterns
   */
  int SetPat(int pat);
  /** print configuration */
  virtual std::ostream &print(std::ostream &os) const;
  /** lookup parameter value
   * @param[in]  key_name
   * @param[out] value
   * @return     found / not found
   */
  template <class T>
  bool Lookup(const std::string &key_name, T &value) const {
    //LOG_DEBUG() << "Lookup Key: " << key_name << "\n";
    if (!tmptbl_.HasKey(key_name)) return false;
    //LOG_DEBUG() << "Key exits: " << key_name << "\n";
    const pu::LuaValue *lv = tmptbl_.Find(key_name)->second;
    lv->get(value);
    return true;
  }
  /** lookup flag value
   * @param[in]  key_name
   * @return     true / false
   */
  bool LookupFlag(const std::string &key_name) const {
    bool f = false;
    if (!Lookup<bool>(key_name, f)) return false;
    return f;
  }
  
  bool LookupFlag(ConfigKey key) const {
    const pu::LuaValue *lv = Lookup(key);
    if (lv == NULL) return false;
    bool b;
    lv->get(b);
    return b;
  }
  
  /** set flag value
   * @param[in]  key_name
   * @param[in]  f ... flag value
   */
  void SetFlag(const std::string &key_name, bool f) {
    pu::LuaBoolean b(f);
    tmptbl_.Insert(key_name, &b);
    return;
  }
  /** accessor for npattern_ */
  int npattern() const { return npattern_; }
  /** accessor for ndynamic_ */
  int ndynamic() const { return ndynamic_; }
  /** accessor for auto_tuning_ */
  bool auto_tuning() const { return auto_tuning_; }
 protected:
  /** number of code patterns */
  int npattern_;
  /** number of dynamic arguments */
  int ndynamic_;
  /** auto tuning flag */
  bool auto_tuning_;
  /** hold configuration values for index of pattern */
  pu::LuaTable tmptbl_;
  /** lookup internal function
   * @param[in]  key_id
   * @return     configuration value
   */
  const pu::LuaValue *LookupInternal(int key_id) const {
    const std::string &name = key_desc_map_.find(key_id)->second;
    if (!tmptbl_.HasKey(name)) return NULL;
    return tmptbl_.Find(name)->second;
  }

};

} // namespace translator
} // namespace kff

#endif

